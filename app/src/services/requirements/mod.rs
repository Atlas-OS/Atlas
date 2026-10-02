//! The system checks that gate an install: the same requirements the Atlas
//! package declares in playbook.conf, evaluated with the same rules as
//! `Entry\Install-Atlas.ps1` where the script has an opinion.

mod bounded;
mod providers;
mod wmi;

use super::system::{self, PowerSource, SystemInfo};
use providers::{
    AntivirusProduct, pending_updates, reboot_markers, third_party_antivirus, windows_activation,
};

/// Installed apps in Windows Settings, where other antivirus software is uninstalled.
const INSTALLED_APPS: &str = "ms-settings:appsfeatures";

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum CheckId {
    Administrator,
    UserAccount,
    SupportedBuild,
    PendingUpdates,
    PendingReboot,
    ThirdPartyAntivirus,
    Internet,
    Power,
    /// Advisory: Atlas never changes activation, but people should know.
    Activation,
}

impl CheckId {
    pub const ALL: [CheckId; 9] = [
        CheckId::Administrator,
        CheckId::UserAccount,
        CheckId::SupportedBuild,
        CheckId::PendingUpdates,
        CheckId::PendingReboot,
        CheckId::ThirdPartyAntivirus,
        CheckId::Internet,
        CheckId::Power,
        CheckId::Activation,
    ];

    /// Whether a failure stops the install, or only warns.
    pub fn blocking(self) -> bool {
        !matches!(self, CheckId::Activation)
    }

    /// A Settings page that helps resolve the failure, if there is one. The
    /// button's label comes from the message catalog.
    pub fn fix_target(self) -> Option<&'static str> {
        match self {
            CheckId::PendingUpdates | CheckId::PendingReboot => Some(system::links::WINDOWS_UPDATE),
            CheckId::ThirdPartyAntivirus => Some(INSTALLED_APPS),
            CheckId::Internet => Some(system::links::NETWORK),
            CheckId::Power => Some(system::links::POWER),
            CheckId::Activation => Some(system::links::ACTIVATION),
            _ => None,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Verdict {
    Pass,
    Warn,
    Fail,
    /// The provider could not establish the fact. Required checks fail closed;
    /// only the update scan has a separate manual acknowledgement path.
    Unknown,
}

/// What a check found, as data. The page translates it when it renders,
/// so a result that is already on screen changes language with the app.
/// Raw error text from Windows is kept as a diagnostic, never as the
/// explanation.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CheckDetail {
    AdministratorOk,
    AdministratorMissing,
    UserAccountOk,
    UserAccountNotReady,
    UserAccountUnknown {
        error: String,
    },
    BuildSupported,
    EditionUnsupported,
    WindowsPreview,
    WindowsReleaseUnknown,
    BuildUnsupported {
        supported: Vec<u32>,
        actual: u32,
    },
    /// The package doesn't support this Windows version, and Atlas moves
    /// Windows to `release` when it updates Windows. Still a failure: the
    /// install can't start on this version.
    BuildTransition {
        /// This PC's version, such as "24H2".
        current: String,
        release: String,
    },
    UpdatesNone,
    UpdatesPending {
        titles: Vec<String>,
    },
    UpdatesUnknown {
        error: String,
    },
    RebootNone,
    /// Marker ids as the preparation worker names them: `servicing`,
    /// `windows-update`.
    RebootPending {
        reasons: Vec<String>,
    },
    /// Only `PendingFileRenameOperations` is set. Apps such as Xbox Gaming
    /// Services queue a file there at every boot, so it does not block; the
    /// files are named so the user can see whose they are.
    RebootFileRenames {
        files: Vec<String>,
    },
    RebootUnknown {
        error: String,
    },
    AntivirusNone,
    AntivirusFound {
        products: Vec<String>,
    },
    /// Security Center still lists these, but the executables they register
    /// are gone: leftovers of an uninstall (Malwarebytes leaves one).
    AntivirusStale {
        products: Vec<String>,
    },
    AntivirusUnknown {
        error: String,
    },
    InternetOk,
    InternetMissing,
    PowerMains,
    PowerBattery,
    PowerUnknown,
    ActivationOk,
    ActivationMissing,
    ActivationNoLicence,
    ActivationUnknown {
        error: String,
    },
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CheckResult {
    pub id: CheckId,
    pub verdict: Verdict,
    pub detail: CheckDetail,
}

impl CheckResult {
    /// Whether this result stops the install on its own. An unknown result
    /// on a blocking check stops it too; only the update scan's can be
    /// acknowledged instead (see [`CheckResult::needs_acknowledgement`]).
    pub fn blocks_install(&self) -> bool {
        self.id.blocking() && matches!(self.verdict, Verdict::Fail | Verdict::Unknown)
    }

    /// Only the update scan can be confirmed manually; safety checks must run.
    pub fn needs_acknowledgement(&self) -> bool {
        self.id == CheckId::PendingUpdates && self.verdict == Verdict::Unknown
    }
}

pub struct CheckContext {
    pub system: SystemInfo,
    pub supported_builds: Vec<u32>,
}

/// Runs one check. Slow checks (Windows Update, WMI) take a few seconds.
pub fn run(id: CheckId, ctx: &CheckContext) -> CheckResult {
    use CheckDetail as D;
    let (verdict, detail) = match id {
        CheckId::Administrator => {
            if system::is_elevated() {
                (Verdict::Pass, D::AdministratorOk)
            } else {
                (Verdict::Fail, D::AdministratorMissing)
            }
        }
        CheckId::UserAccount => match system::user_account_ready() {
            Ok(true) => (Verdict::Pass, D::UserAccountOk),
            Ok(false) => (Verdict::Fail, D::UserAccountNotReady),
            Err(error) => (Verdict::Unknown, D::UserAccountUnknown { error: format!("{error:#}") }),
        },
        CheckId::SupportedBuild => {
            if !ctx.system.supported_edition() {
                (Verdict::Fail, D::EditionUnsupported)
            } else if ctx.supported_builds.contains(&ctx.system.build) {
                match super::windows_release::classify(
                    ctx.system.build,
                    ctx.system.revision,
                    &ctx.system.build_lab,
                ) {
                    super::windows_release::Status::Released => (Verdict::Pass, D::BuildSupported),
                    super::windows_release::Status::Preview => (Verdict::Fail, D::WindowsPreview),
                    super::windows_release::Status::Unknown => (Verdict::Unknown, D::WindowsReleaseUnknown),
                }
            } else if let Some((transition, _)) = super::windows_release::transition_for(
                &ctx.system,
                &ctx.supported_builds,
                super::desktop_setup::active(),
            ) {
                (
                    Verdict::Fail,
                    D::BuildTransition {
                        current: ctx.system.display_version.clone(),
                        release: transition.target_release.to_owned(),
                    },
                )
            } else {
                (
                    Verdict::Fail,
                    D::BuildUnsupported { supported: ctx.supported_builds.clone(), actual: ctx.system.build },
                )
            }
        }
        CheckId::PendingUpdates => match pending_updates() {
            Ok(titles) if titles.is_empty() => (Verdict::Pass, D::UpdatesNone),
            Ok(titles) => (Verdict::Fail, D::UpdatesPending { titles }),
            Err(error) => (Verdict::Unknown, D::UpdatesUnknown { error: format!("{error:#}") }),
        },
        CheckId::PendingReboot => match reboot_markers() {
            Ok(markers) => reboot_verdict(markers),
            Err(error) => (Verdict::Unknown, D::RebootUnknown { error: format!("{error:#}") }),
        },
        CheckId::ThirdPartyAntivirus => match third_party_antivirus() {
            Ok(products) => {
                let (installed, stale): (Vec<_>, Vec<_>) =
                    products.into_iter().partition(AntivirusProduct::installed);
                let names = |products: Vec<AntivirusProduct>| products.into_iter().map(|p| p.name).collect();
                if !installed.is_empty() {
                    (Verdict::Fail, D::AntivirusFound { products: names(installed) })
                } else if !stale.is_empty() {
                    (Verdict::Warn, D::AntivirusStale { products: names(stale) })
                } else {
                    (Verdict::Pass, D::AntivirusNone)
                }
            }
            Err(error) => (Verdict::Unknown, D::AntivirusUnknown { error: format!("{error:#}") }),
        },
        CheckId::Internet => {
            if system::internet_connected() {
                (Verdict::Pass, D::InternetOk)
            } else {
                (Verdict::Fail, D::InternetMissing)
            }
        }
        CheckId::Power => match system::power_source() {
            PowerSource::Mains => (Verdict::Pass, D::PowerMains),
            PowerSource::Battery => (Verdict::Fail, D::PowerBattery),
            PowerSource::Unknown => (Verdict::Unknown, D::PowerUnknown),
        },
        CheckId::Activation => match windows_activation() {
            Ok(Some(true)) => (Verdict::Pass, D::ActivationOk),
            Ok(Some(false)) => (Verdict::Warn, D::ActivationMissing),
            Ok(None) => (Verdict::Unknown, D::ActivationNoLicence),
            Err(error) => (Verdict::Unknown, D::ActivationUnknown { error: format!("{error:#}") }),
        },
    };
    if verdict == Verdict::Unknown {
        log::warn!("check {id:?} could not run: {detail:?}");
    }
    CheckResult { id, verdict, detail }
}

/// Whether Windows owes a restart, from the flags servicing and Windows Update
/// set for it. Pending file replacements on their own are only a note: an
/// update can queue some (printer drivers, for one) without either flag, and
/// apps such as Xbox Gaming Services queue one at every boot.
fn reboot_verdict(markers: providers::RebootMarkers) -> (Verdict, CheckDetail) {
    if !markers.blocking.is_empty() {
        (
            Verdict::Fail,
            CheckDetail::RebootPending {
                reasons: markers.blocking.iter().map(|r| (*r).to_owned()).collect(),
            },
        )
    } else if !markers.file_renames.is_empty() {
        (Verdict::Pass, CheckDetail::RebootFileRenames { files: markers.file_renames })
    } else {
        (Verdict::Pass, CheckDetail::RebootNone)
    }
}

#[cfg(test)]
mod tests {

    /// The 20 printer driver replacements the September 2026 cumulative update
    /// left after its restart, with neither restart flag set.
    #[test]
    fn file_replacements_without_a_restart_flag_never_need_attention() {
        let driver = |name: &str| format!(r"C:\Windows\System32\spool\drivers\x64\3\New\{name}");
        let files: Vec<String> =
            ["MXDWDRV.DLL", "PJLMON.DLL", "PS5UI.DLL", "PSCRIPT5.DLL", "UNIDRV.DLL", "UNIDRVUI.DLL"]
                .iter()
                .map(|name| driver(name))
                .collect();
        let (verdict, detail) =
            reboot_verdict(providers::RebootMarkers { blocking: vec![], file_renames: files.clone() });
        assert_eq!(verdict, Verdict::Pass);
        assert_eq!(detail, CheckDetail::RebootFileRenames { files: files.clone() });
        let (verdict, _) =
            reboot_verdict(providers::RebootMarkers { blocking: vec!["servicing"], file_renames: files });
        assert_eq!(verdict, Verdict::Fail, "a restart flag still needs a restart");
        assert_eq!(
            reboot_verdict(providers::RebootMarkers { blocking: vec![], file_renames: vec![] }),
            (Verdict::Pass, CheckDetail::RebootNone)
        );
    }
    use super::*;

    fn result(id: CheckId, verdict: Verdict) -> CheckResult {
        CheckResult { id, verdict, detail: CheckDetail::InternetOk }
    }

    #[test]
    fn unknown_blocking_checks_block_until_acknowledged() {
        assert!(result(CheckId::PendingUpdates, Verdict::Unknown).blocks_install());
        assert!(result(CheckId::PendingUpdates, Verdict::Unknown).needs_acknowledgement());
        assert!(result(CheckId::PendingUpdates, Verdict::Fail).blocks_install());
        assert!(!result(CheckId::PendingUpdates, Verdict::Fail).needs_acknowledgement());
        assert!(!result(CheckId::PendingUpdates, Verdict::Pass).blocks_install());
        // Required safety checks cannot be bypassed when their provider fails.
        for id in [CheckId::UserAccount, CheckId::Power, CheckId::ThirdPartyAntivirus, CheckId::PendingReboot]
        {
            for verdict in [Verdict::Fail, Verdict::Unknown] {
                assert!(result(id, verdict).blocks_install());
                assert!(!result(id, verdict).needs_acknowledgement());
            }
        }
        // Activation remains advisory.
        for verdict in [Verdict::Warn, Verdict::Fail, Verdict::Unknown] {
            assert!(!result(CheckId::Activation, verdict).blocks_install());
        }
    }

    /// The edition gate comes before the build list (system.rs tests the full
    /// edition list), and a build the package does not list blocks.
    #[test]
    fn supported_build_does_not_override_an_unsupported_or_unknown_edition() {
        let mut context = CheckContext {
            system: SystemInfo {
                build: 26200,
                revision: 6584,
                installation_type: "Client".into(),
                ..Default::default()
            },
            supported_builds: vec![26200],
        };
        for edition in ["", "Core", "EnterpriseS"] {
            context.system.edition_id = edition.into();
            let result = run(CheckId::SupportedBuild, &context);
            assert!(result.blocks_install(), "{edition}");
            assert_eq!(result.detail, CheckDetail::EditionUnsupported);
        }
        context.system.edition_id = "Professional".into();
        assert_eq!(run(CheckId::SupportedBuild, &context).verdict, Verdict::Pass);
        context.system.build = 22631;
        let result = run(CheckId::SupportedBuild, &context);
        assert!(result.blocks_install());
        assert_eq!(result.detail, CheckDetail::BuildUnsupported { supported: vec![26200], actual: 22631 });
        // A version Atlas moves from still fails: the install can't start on it.
        context.system.build = 26100;
        context.system.display_version = "24H2".into();
        context.supported_builds = vec![26200, 26300];
        let result = run(CheckId::SupportedBuild, &context);
        assert!(result.blocks_install());
        assert_eq!(
            result.detail,
            CheckDetail::BuildTransition { current: "24H2".into(), release: "26H2".into() }
        );
        // Home on that version is ruled out by its edition first.
        context.system.edition_id = "Core".into();
        assert_eq!(run(CheckId::SupportedBuild, &context).detail, CheckDetail::EditionUnsupported);
        context.system.edition_id = "Professional".into();
        context.supported_builds = vec![26200];
        context.system.build = 26200;
        context.system.installation_type = "Server".into();
        assert!(run(CheckId::SupportedBuild, &context).blocks_install());
    }
}
