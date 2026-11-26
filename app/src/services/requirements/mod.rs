//! The system checks that gate an install: the requirements the Atlas
//! package lists in its manifest (`no-third-party-antivirus` and
//! `plugged-in`; the Windows Security step covers `windows-security-off`)
//! and the ones the front door always checks, evaluated with the same rules
//! as `Entry\Install-Atlas.ps1` where the script has an opinion. Where Get
//! ready moves Windows to a newer release, it also checks what the move
//! needs ([`CheckId::MOVE`]), by the preparation worker's rules.

mod deadline;
mod providers;
pub(in crate::services) mod wmi;

use super::system::{self, PowerSource, SystemInfo};
use providers::{
    AntivirusProduct, Hardware, free_space, managed_update_server, pending_updates, reboot_markers,
    third_party_antivirus, windows_11_hardware, windows_activation,
};

/// Installed apps in Windows Settings, where other antivirus software is uninstalled.
const INSTALLED_APPS: &str = "ms-settings:appsfeatures";
/// Storage in Windows Settings, where space is freed up.
const STORAGE: &str = "ms-settings:storagesense";
/// The free space a move to a newer Windows release needs on the system drive,
/// in GiB: the preparation worker's own minimum (`Test-AtlasWindowsTransitionPreflight`).
pub const MOVE_SPACE_GB: u64 = 6;

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
    /// Moving Windows: the hardware Windows 11 requires, where it can be read.
    MoveHardware,
    /// Moving Windows: free space on the system drive.
    MoveSpace,
    /// Moving Windows: updates come from Windows Update, not an organisation's server.
    MoveUpdateSource,
}

impl CheckId {
    /// What a move to a newer Windows release needs that Windows Update
    /// would otherwise refuse only after the move had begun. Get ready runs
    /// these only where a move applies; the install never needs them.
    pub const MOVE: [CheckId; 3] = [CheckId::MoveHardware, CheckId::MoveSpace, CheckId::MoveUpdateSource];

    /// Whether this check is one of [`CheckId::MOVE`].
    pub fn for_move(self) -> bool {
        Self::MOVE.contains(&self)
    }

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
            CheckId::MoveSpace => Some(STORAGE),
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
    /// A work or school (Microsoft Entra ID) account, or any other account
    /// without an account SID: the install plan can't act for it.
    UserAccountWorkOrSchool,
    UserAccountUnknown {
        error: String,
    },
    BuildSupported,
    EditionUnsupported,
    WindowsPreview,
    /// Microsoft's list of public releases doesn't include this build.
    WindowsReleaseUnlisted,
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
    /// No move to a newer Windows release applies here.
    MoveNotNeeded,
    HardwareReady,
    /// Windows 11 hardware this PC lacks, as the preparation worker names it
    /// (`tpm`, `uefi`), which `release` needs.
    HardwareMissing {
        missing: Vec<String>,
        release: String,
    },
    /// Some of it couldn't be read, as without administrator rights; Windows
    /// Update decides then.
    HardwareUnread,
    /// `drive` (such as "C:") has `free_gb` whole GiB free.
    SpaceEnough {
        drive: String,
        free_gb: u64,
    },
    SpaceLow {
        drive: String,
        free_gb: u64,
        needed_gb: u64,
        release: String,
    },
    SpaceUnknown {
        error: String,
    },
    UpdateSourceMicrosoft,
    /// Updates come from an organisation's server (`AU\UseWUServer`), which
    /// doesn't offer `release` as Windows Update would.
    UpdateSourceManaged {
        release: String,
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
        CheckId::UserAccount => match system::user_has_account_sid() {
            Ok(false) => (Verdict::Fail, D::UserAccountWorkOrSchool),
            Ok(true) => match system::user_account_ready() {
                Ok(true) => (Verdict::Pass, D::UserAccountOk),
                Ok(false) => (Verdict::Fail, D::UserAccountNotReady),
                Err(error) => (Verdict::Unknown, D::UserAccountUnknown { error: format!("{error:#}") }),
            },
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
                    super::windows_release::Status::Unlisted => (Verdict::Fail, D::WindowsReleaseUnlisted),
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
        CheckId::MoveHardware | CheckId::MoveSpace | CheckId::MoveUpdateSource => {
            match super::windows_release::transition_for(
                &ctx.system,
                &ctx.supported_builds,
                super::desktop_setup::active(),
            ) {
                None => (Verdict::Pass, D::MoveNotNeeded),
                Some((transition, _)) => move_check(id, transition.target_release),
            }
        }
    };
    // Checks run when asked, not on a timer, so the log keeps every result that held
    // the install back.
    match verdict {
        Verdict::Unknown => log::warn!("check {id:?} could not run: {detail:?}"),
        Verdict::Fail => log::info!("check {id:?} failed: {detail:?}"),
        _ => {}
    }
    CheckResult { id, verdict, detail }
}

/// What a move to `release` needs from this PC, read before anything changes,
/// by the rules the preparation worker refuses a move with.
fn move_check(id: CheckId, release: &str) -> (Verdict, CheckDetail) {
    use CheckDetail as D;
    let release = release.to_owned();
    match id {
        CheckId::MoveHardware => hardware_verdict(windows_11_hardware(), release),
        CheckId::MoveSpace => match free_space() {
            Ok((drive, bytes)) => space_verdict(drive, bytes, release),
            Err(error) => (Verdict::Unknown, D::SpaceUnknown { error: format!("{error:#}") }),
        },
        _ if managed_update_server() => (Verdict::Fail, D::UpdateSourceManaged { release }),
        _ => (Verdict::Pass, D::UpdateSourceMicrosoft),
    }
}

/// Hardware this PC is known to lack fails; what can't be read doesn't.
fn hardware_verdict(hardware: Hardware, release: String) -> (Verdict, CheckDetail) {
    let mut missing = Vec::new();
    if hardware.tpm_2 == Some(false) {
        missing.push("tpm".to_owned());
    }
    if hardware.uefi == Some(false) {
        missing.push("uefi".to_owned());
    }
    if !missing.is_empty() {
        (Verdict::Fail, CheckDetail::HardwareMissing { missing, release })
    } else if hardware.tpm_2.is_none() || hardware.uefi.is_none() {
        (Verdict::Pass, CheckDetail::HardwareUnread)
    } else {
        (Verdict::Pass, CheckDetail::HardwareReady)
    }
}

/// Whole GiB, rounded down, against [`MOVE_SPACE_GB`].
fn space_verdict(drive: String, bytes: u64, release: String) -> (Verdict, CheckDetail) {
    const GIB: u64 = 1 << 30;
    let free_gb = bytes / GIB;
    if bytes < MOVE_SPACE_GB * GIB {
        (Verdict::Fail, CheckDetail::SpaceLow { drive, free_gb, needed_gb: MOVE_SPACE_GB, release })
    } else {
        (Verdict::Pass, CheckDetail::SpaceEnough { drive, free_gb })
    }
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

    /// The check that evaluates a manifest requirement before the front door
    /// does, by the requirement's id; `None` for one the Windows Security step
    /// evaluates, or one this app doesn't know.
    fn check_for(requirement: &str) -> Option<CheckId> {
        match requirement {
            "no-third-party-antivirus" => Some(CheckId::ThirdPartyAntivirus),
            "plugged-in" => Some(CheckId::Power),
            _ => None,
        }
    }

    /// Every requirement the built-in manifest lists stops an install here
    /// too, so Get ready never sends on an install the front door refuses.
    #[test]
    fn every_requirement_the_package_lists_has_a_blocking_check_or_step() {
        let requirements = crate::services::package::Manifest::builtin().requirements;
        assert!(!requirements.is_empty());
        for requirement in &requirements {
            match check_for(requirement) {
                Some(id) => assert!(id.blocking(), "{requirement}: {id:?} only warns"),
                None => assert_eq!(requirement, "windows-security-off", "no check evaluates {requirement}"),
            }
        }
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

    /// Hardware known to be missing fails the move; what can't be read is
    /// left to Windows Update.
    #[test]
    fn the_move_checks_fail_only_on_what_they_could_read() {
        let release = || "26H2".to_owned();
        let hardware = |tpm_2, uefi| hardware_verdict(Hardware { tpm_2, uefi }, release());
        assert_eq!(hardware(Some(true), Some(true)), (Verdict::Pass, CheckDetail::HardwareReady));
        assert_eq!(hardware(None, Some(true)), (Verdict::Pass, CheckDetail::HardwareUnread));
        assert_eq!(
            hardware(Some(false), None),
            (Verdict::Fail, CheckDetail::HardwareMissing { missing: vec!["tpm".into()], release: release() })
        );
        assert_eq!(
            hardware(Some(false), Some(false)).1,
            CheckDetail::HardwareMissing { missing: vec!["tpm".into(), "uefi".into()], release: release() }
        );
        const GIB: u64 = 1 << 30;
        assert_eq!(
            space_verdict("C:".into(), 6 * GIB, release()),
            (Verdict::Pass, CheckDetail::SpaceEnough { drive: "C:".into(), free_gb: 6 })
        );
        assert_eq!(
            space_verdict("C:".into(), 6 * GIB - 1, release()),
            (
                Verdict::Fail,
                CheckDetail::SpaceLow { drive: "C:".into(), free_gb: 5, needed_gb: 6, release: release() }
            )
        );
        // Where no move applies, there's nothing to check.
        let context = CheckContext {
            system: SystemInfo {
                build: 26200,
                revision: 6584,
                edition_id: "Professional".into(),
                installation_type: "Client".into(),
                ..Default::default()
            },
            supported_builds: vec![26200],
        };
        for id in CheckId::MOVE {
            assert!(id.for_move() && id.blocking(), "{id:?}");
            assert_eq!(run(id, &context).detail, CheckDetail::MoveNotNeeded, "{id:?}");
        }
        assert!(!CheckId::ALL.iter().any(|id| id.for_move()), "the install never runs them");
    }

    /// On a listed build, Windows's release decides; neither case reaches
    /// Microsoft's page. An Insider build fails, and a release that can't be
    /// established blocks without a way to acknowledge it.
    #[test]
    fn a_listed_build_still_needs_a_public_release() {
        let mut context = CheckContext {
            system: SystemInfo {
                build: 26200,
                revision: 6584,
                edition_id: "Professional".into(),
                installation_type: "Client".into(),
                build_lab: "26200.1.amd64fre.rs_prerelease.250101".into(),
                ..Default::default()
            },
            supported_builds: vec![26200],
        };
        let result = run(CheckId::SupportedBuild, &context);
        assert_eq!((result.verdict, &result.detail), (Verdict::Fail, &CheckDetail::WindowsPreview));
        assert!(result.blocks_install());
        context.system.revision = 0;
        context.system.build_lab = "26200.1.amd64fre.ge_release.250101".into();
        let result = run(CheckId::SupportedBuild, &context);
        assert_eq!((result.verdict, &result.detail), (Verdict::Unknown, &CheckDetail::WindowsReleaseUnknown));
        assert!(result.blocks_install());
        assert!(!result.needs_acknowledgement());
    }
}
