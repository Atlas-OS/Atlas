//! Words for the app's semantic state. Services and the model keep facts
//! (a check's verdict and what it found, an outcome and the phase it ended
//! in, a notice's cause); these functions turn them into sentences in the
//! current language when a page renders, so switching language re-words
//! everything already on screen.
//!
//! Raw diagnostics (Windows error text, paths, versions, build numbers) are
//! passed through as text arguments and never translated or reformatted.

use crate::model::{
    AcquireProblem, ElevationProblem, FixedChoice, InstallBlock, Notice, Preflight, ProtectionReminder,
    ScreenKind,
};
use crate::services::atlas_state::InstallMode;
use crate::services::installer::{InstallOutcome, Phase};
use crate::services::legacy_choices::Facts;
use crate::services::package::Choice;
use crate::services::preparation::{Activity, waits_for_offer};
use crate::services::reports::SendProblem;
use crate::services::requirements::{CheckDetail, CheckId, CheckResult};
use crate::services::security::{Protection, SwitchCounts};
use crate::services::settings::SettingsProblem;
use crate::services::system::SystemInfo;
use crate::services::windows_release::WindowsBlock;
use crate::t;

/// Joins items with the language's list separator: "Brave, Firefox".
pub fn join_list(items: &[String]) -> String {
    let separator = t!("list-separator");
    items.join(&separator)
}

/// Joins items as a list that ends with the language's "and": "Tamper
/// Protection, Real-time protection and Cloud-delivered protection".
pub fn join_and(items: &[String]) -> String {
    match items {
        [] => String::new(),
        [only] => only.clone(),
        [head @ .., last] => t!("list-and", a = join_list(head), b = last.as_str()),
    }
}

/// The user-facing name of a pending-restart marker id reported by the
/// checks or the preparation worker. An id this build does not know is shown
/// as it came, so a newer worker still says something.
pub fn restart_reason(id: &str) -> String {
    match id {
        "servicing" => t!("prepare-reason-servicing"),
        "windows-update" => t!("prepare-reason-windows-update"),
        "file-renames" => t!("prepare-reason-file-renames"),
        "update-agent" => t!("prepare-reason-update-agent"),
        "feature-update" => t!("prepare-reason-feature-update"),
        "feature-commit" => t!("prepare-reason-feature-commit"),
        "apprepository" => t!("prepare-reason-apprepository"),
        other => other.to_owned(),
    }
}

pub fn restart_reasons(ids: &[String]) -> String {
    if ids.is_empty() {
        return t!("prepare-reason-unknown");
    }
    let names: Vec<String> = ids.iter().map(|id| restart_reason(id)).collect();
    join_list(&names)
}

/// A Store update could not replace an app that is running.
const ERROR_PACKAGES_IN_USE: &str = "0x80073D02";
/// Windows Update refused to start while another install or a required
/// restart is pending.
const WU_E_INSTALL_NOT_ALLOWED: &str = "0x80240016";
/// Windows found its component store damaged, so no update can install.
const ERROR_SXS_COMPONENT_STORE_CORRUPT: &str = "0x80073712";
/// The cause the worker names when Windows records damage to its component
/// store that it can't repair.
const COMPONENT_STORE_UNREPAIRABLE: &str = "component-store-unrepairable";

/// Windows records damage to its component store that it can't repair:
/// reinstalling Windows is the way on, and trying again can't help.
pub fn component_store_unrepairable(failure: &Activity) -> bool {
    failure.reason.as_deref() == Some(COMPONENT_STORE_UNREPAIRABLE)
}

/// An update still failed on the component store after Atlas's repair,
/// which a restart can clear.
pub fn component_store_still_damaged(failure: &Activity) -> bool {
    !component_store_unrepairable(failure)
        && failure
            .error_code
            .as_deref()
            .is_some_and(|code| code.eq_ignore_ascii_case(ERROR_SXS_COMPONENT_STORE_CORRUPT))
}

/// The status a failed run gets where its cause has one of its own: a
/// damaged component store, and a Microsoft Store Atlas couldn't repair.
pub fn preparation_failure_title(failure: &Activity) -> Option<String> {
    if component_store_unrepairable(failure) {
        Some(t!("prepare-components-unrepairable-title"))
    } else if component_store_still_damaged(failure) {
        Some(t!("prepare-components-damaged-title"))
    } else if failure.reason.as_deref() == Some("store-repair-failed") {
        Some(t!("prepare-store-broken-title"))
    } else {
        None
    }
}

/// What to do about a preparation run that failed. `failure` is the
/// worker's own report, if it wrote one; `has_error` says the app recorded
/// an error of its own. A run that ended with neither is not called a
/// failure it cannot describe.
pub fn preparation_failure(failure: Option<&Activity>, has_error: bool) -> String {
    let Some(failure) = failure else {
        return if has_error { t!("prepare-failed-retry") } else { t!("prepare-unconfirmed") };
    };
    match failure.error_code.as_deref() {
        Some(code) if code.eq_ignore_ascii_case(ERROR_PACKAGES_IN_USE) => {
            let app = failure.package_name.clone().unwrap_or_else(|| t!("prepare-affected-app"));
            t!("prepare-close-app", app = app)
        }
        Some(code) if code.eq_ignore_ascii_case(WU_E_INSTALL_NOT_ALLOWED) => t!("prepare-install-busy"),
        _ if component_store_still_damaged(failure) => t!("prepare-components-damaged"),
        _ => failure
            .reason
            .as_deref()
            .and_then(preparation_failure_reason)
            .unwrap_or_else(|| t!("prepare-failed-retry")),
    }
}

/// Advice for a cause the preparation worker names. An id this build does
/// not know gets the general message instead.
pub fn preparation_failure_reason(id: &str) -> Option<String> {
    Some(match id {
        "session-owner" => t!("prepare-failed-session-owner"),
        "store-missing" => t!("prepare-failed-store-missing"),
        "store-paused-battery" => t!("prepare-failed-store-battery"),
        "store-paused-network" => t!("prepare-failed-store-network"),
        "store-timeout" => t!("prepare-failed-store-timeout"),
        "store-passes" => t!("prepare-failed-store-passes"),
        "store-repair-failed" => t!("prepare-store-broken"),
        COMPONENT_STORE_UNREPAIRABLE => t!("prepare-components-unrepairable"),
        "manual-updates" => t!("prepare-failed-manual-updates"),
        "windows-passes" => t!("prepare-failed-windows-passes"),
        _ => return None,
    })
}

/// What preparation did about Microsoft Store itself, said once it's done,
/// where it changes what the user can expect: Store apps left as they were
/// because Microsoft Store is turned off. Updating, reinstalling or
/// repairing Microsoft Store on the way changes nothing the user does, so
/// only the log keeps it.
pub fn store_outcome(outcome: crate::services::preparation::StoreOutcome) -> Option<String> {
    use crate::services::preparation::StoreOutcome;
    match outcome {
        StoreOutcome::SkippedRemoved => Some(t!("prepare-store-skipped-removed")),
        StoreOutcome::Updated | StoreOutcome::Bootstrapped | StoreOutcome::Repaired => None,
    }
}

/// The release names a move needs for its wording: where Windows goes
/// (`release`), where it is (`current`) and the Atlas version it's for.
pub struct TransitionWords<'a> {
    pub release: &'a str,
    pub current: &'a str,
    pub version: &'a str,
}

/// How something ended, as a title that names it and up to two sentences on
/// what to do next.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Outcome {
    pub title: String,
    pub body: String,
}

/// What a move between Windows releases ended with and what to do next, for
/// a cause the update worker names. `None` for any other failure.
pub fn transition_outcome(failure: &Activity, words: &TransitionWords) -> Option<Outcome> {
    let (release, current, version) = (words.release, words.current, words.version);
    let reason = failure.reason.as_deref()?;
    let setting = || failure.setting.clone().unwrap_or_default();
    let (title, body) = match reason {
        // A missing monthly update is installed first; one Windows Update
        // doesn't offer yet is the same wait as the release itself.
        reason if waits_for_offer(reason) => (
            t!("windows-outcome-not-offered-title", release = release),
            t!("windows-outcome-not-offered", current = current),
        ),
        "feature-hardware" => (
            t!("windows-outcome-hardware-title"),
            t!(
                "windows-outcome-hardware",
                missing = hardware_list(
                    &failure.hardware.as_deref().unwrap_or_default().split(',').collect::<Vec<_>>()
                ),
                release = release
            ),
        ),
        "feature-hidden" => {
            (t!("windows-outcome-hidden-title", release = release), t!("windows-outcome-hidden"))
        }
        "feature-disk-space" => (
            t!("windows-outcome-disk-space-title"),
            t!(
                "windows-outcome-disk-space",
                needed = failure.needed_gb.clone().unwrap_or_default(),
                drive = failure.drive.clone().unwrap_or_default(),
                free = failure.free_gb.clone().unwrap_or_default()
            ),
        ),
        // The component store Windows can't repair, as before any update.
        "feature-servicing" => {
            (t!("prepare-components-unrepairable-title"), t!("prepare-components-unrepairable"))
        }
        "feature-managed" => {
            (t!("windows-outcome-managed-title"), t!("windows-outcome-managed", release = release))
        }
        "feature-policy" => {
            (t!("windows-outcome-policy-title"), t!("windows-outcome-policy", setting = setting()))
        }
        "feature-blocked" => match service_name(&setting()) {
            Some(service) => (
                t!("windows-outcome-service-off-title", service = service),
                t!("windows-outcome-blocked-service"),
            ),
            None => (t!("windows-outcome-blocked-title"), t!("windows-outcome-blocked", setting = setting())),
        },
        "feature-rolled-back" => (
            t!("windows-outcome-rollback-title", release = release),
            t!("windows-outcome-rolled-back", current = current),
        ),
        "feature-components-lost" => (
            t!("windows-outcome-components-lost-title"),
            t!("windows-outcome-components-lost", version = version),
        ),
        "feature-build" => (t!("windows-outcome-build-title"), t!("windows-outcome-build")),
        "feature-journal" => (t!("windows-outcome-journal-title"), t!("windows-outcome-journal")),
        "feature-pin" => (t!("windows-outcome-pin-title"), t!("windows-outcome-pin", setting = setting())),
        "feature-terms" => {
            (t!("windows-outcome-terms-title"), t!("windows-outcome-terms", release = release))
        }
        "feature-failed" => (
            t!("windows-outcome-failed-title", release = release),
            t!("windows-outcome-failed", current = current),
        ),
        _ => return None,
    };
    Some(Outcome { title, body })
}

/// A Windows service a move needs, by its Windows name, as Services lists
/// it; `None` for a setting that isn't one of them.
pub fn service_name(setting: &str) -> Option<String> {
    Some(match setting {
        "BITS" => t!("service-bits"),
        "CryptSvc" => t!("service-cryptsvc"),
        "TrustedInstaller" => t!("service-trusted-installer"),
        _ => return None,
    })
}

/// Why putting the Windows Update settings back failed, for a cause the
/// worker names; `None` for any other error, which only its raw text and the
/// log explain.
pub fn restore_failure_cause(error: &str) -> Option<String> {
    match crate::services::preparation::operation_reason(error) {
        Some("feature-install-active") => Some(t!("update-access-finish-install")),
        Some("feature-journal") => Some(t!("home-update-access-unreadable-problem")),
        _ => None,
    }
}

/// Why preparation needs another connection, from the cause the worker
/// reported. Older workers report none.
pub fn preparation_network(reason: Option<&str>) -> String {
    match reason {
        Some("limited") => t!("prepare-network-limited"),
        Some("metered") => t!("prepare-network-metered"),
        _ => t!("prepare-network-unmetered"),
    }
}

/// Joins alternatives: "26100 or 26200".
pub fn join_or(items: &[String]) -> String {
    let mut iter = items.iter();
    let Some(first) = iter.next() else { return String::new() };
    iter.fold(first.clone(), |acc, next| t!("list-or", a = acc, b = next))
}

/// "900 MB" or "6.1 GB": a file size in the unit that suits it.
pub fn file_size(bytes: u64) -> String {
    let unit = super::fmt::SizeUnit::of(bytes);
    let size = unit.value(bytes);
    match unit {
        super::fmt::SizeUnit::Megabytes => t!("size-megabytes", size = size),
        super::fmt::SizeUnit::Gigabytes => t!("size-gigabytes", size = size),
    }
}

/// "Windows 11 Pro 25H2 (build 26200.1234)".
pub fn system_description(system: &SystemInfo) -> String {
    t!(
        "system-description",
        product = system.product_name.as_str(),
        version = system.display_version.as_str(),
        build = system.build_label()
    )
}

impl crate::flow::Step {
    pub fn title(self) -> String {
        use crate::flow::Step;
        match self {
            Step::Ready => t!("step-ready"),
            Step::Options => t!("step-options"),
            Step::Security => t!("step-security"),
            Step::Install => t!("step-install"),
        }
    }
}

impl CheckId {
    pub fn title(self) -> String {
        match self {
            CheckId::Administrator => t!("check-administrator"),
            CheckId::UserAccount => t!("check-user-account"),
            CheckId::SupportedBuild => t!("check-supported-build"),
            CheckId::PendingUpdates => t!("check-pending-updates"),
            CheckId::PendingReboot => t!("check-pending-reboot"),
            CheckId::ThirdPartyAntivirus => t!("check-third-party-antivirus"),
            CheckId::Internet => t!("check-internet"),
            CheckId::Power => t!("check-power"),
            CheckId::Activation => t!("check-activation"),
            CheckId::MoveHardware => t!("check-move-hardware"),
            CheckId::MoveSpace => t!("check-move-space"),
            CheckId::MoveUpdateSource => t!("check-move-update-source"),
        }
    }

    /// Label for the button that opens the Settings page in `fix_target`.
    pub fn fix_label(self) -> Option<String> {
        Some(match self {
            CheckId::PendingUpdates | CheckId::PendingReboot => t!("check-fix-windows-update"),
            CheckId::ThirdPartyAntivirus => t!("check-fix-installed-apps"),
            CheckId::Internet => t!("check-fix-network"),
            CheckId::Power => t!("check-fix-power"),
            CheckId::Activation => t!("check-fix-activation"),
            CheckId::MoveSpace => t!("check-fix-storage"),
            _ => return None,
        })
    }
}

impl CheckResult {
    /// What the user confirms by hand, for the one result that allows it
    /// (see [`CheckResult::needs_acknowledgement`]).
    pub fn acknowledgement(&self) -> Option<String> {
        self.needs_acknowledgement().then(|| t!("check-ack-updates"))
    }
}

impl CheckDetail {
    pub fn text(&self, system: &SystemInfo) -> String {
        match self {
            CheckDetail::AdministratorOk => t!("detail-admin-ok"),
            CheckDetail::AdministratorMissing => t!("detail-admin-missing"),
            CheckDetail::UserAccountOk => t!("detail-user-account-ok"),
            CheckDetail::UserAccountNotReady => t!("detail-user-account-not-ready"),
            CheckDetail::UserAccountWorkOrSchool => t!("detail-user-account-work-or-school"),
            CheckDetail::UserAccountUnknown { error } => {
                t!("detail-user-account-check-failed", error = error)
            }
            CheckDetail::BuildSupported => system_description(system),
            CheckDetail::EditionUnsupported => t!("detail-edition-unsupported"),
            CheckDetail::WindowsPreview => t!("detail-windows-preview"),
            CheckDetail::WindowsReleaseUnlisted => {
                t!(
                    "detail-windows-release-not-listed",
                    build = format!("{}.{}", system.build, system.revision)
                )
            }
            CheckDetail::WindowsReleaseUnknown => t!("detail-windows-release-unknown"),
            CheckDetail::BuildTransition { current, release } => {
                t!("detail-build-needs-release", current = current.as_str(), release = release.as_str())
            }
            CheckDetail::BuildUnsupported { supported, actual } => {
                if supported.is_empty() {
                    return t!("detail-build-missing");
                }
                let builds: Vec<String> = supported.iter().map(u32::to_string).collect();
                t!("detail-build-unsupported", builds = join_or(&builds), build = actual.to_string())
            }
            CheckDetail::UpdatesNone => t!("detail-updates-none"),
            // The update titles are for the log; Windows Update lists them.
            CheckDetail::UpdatesPending { titles } => t!("detail-updates-left", count = titles.len()),
            CheckDetail::UpdatesUnknown { error } => t!("detail-updates-scan-failed", error = error),
            CheckDetail::RebootNone => t!("detail-reboot-none"),
            CheckDetail::RebootPending { reasons } if reasons.is_empty() => t!("detail-restart-pending"),
            CheckDetail::RebootPending { reasons } => {
                t!("detail-restart-pending-reasons", reasons = restart_reasons(reasons))
            }
            CheckDetail::RebootFileRenames { files } => {
                let shown: Vec<String> = files.iter().take(3).cloned().collect();
                t!("detail-reboot-file-renames", files = join_list(&shown))
            }
            CheckDetail::RebootUnknown { error } => t!("detail-reboot-unknown", error = error),
            CheckDetail::AntivirusNone => t!("detail-antivirus-none"),
            CheckDetail::AntivirusFound { products } => {
                t!("detail-antivirus-uninstall", products = join_list(products))
            }
            CheckDetail::AntivirusStale { products } => {
                t!("detail-antivirus-stale", products = join_list(products))
            }
            CheckDetail::AntivirusUnknown { error } => t!("detail-antivirus-check-failed", error = error),
            CheckDetail::InternetOk => t!("detail-internet-ok"),
            CheckDetail::InternetMissing => t!("detail-internet-missing"),
            CheckDetail::PowerMains => t!("detail-power-mains"),
            CheckDetail::PowerBattery => t!("detail-power-battery"),
            CheckDetail::PowerUnknown => t!("detail-power-check-failed"),
            CheckDetail::ActivationOk => t!("detail-activation-ok"),
            CheckDetail::ActivationMissing => t!("detail-activation-missing"),
            CheckDetail::ActivationNoLicence => t!("detail-activation-no-licence"),
            CheckDetail::ActivationUnknown { error } => t!("detail-activation-unknown", error = error),
            CheckDetail::MoveNotNeeded => t!("detail-move-not-needed"),
            CheckDetail::HardwareReady => t!("detail-move-hardware-ready"),
            CheckDetail::HardwareMissing { missing, release } => {
                t!(
                    "detail-move-hardware-missing",
                    missing = hardware_list(missing),
                    release = release.as_str()
                )
            }
            CheckDetail::HardwareUnread => t!("detail-move-hardware-unread"),
            CheckDetail::SpaceEnough { drive, free_gb } => {
                t!("detail-move-space-ok", drive = drive.as_str(), free = free_gb.to_string())
            }
            CheckDetail::SpaceLow { drive, free_gb, needed_gb, release } => t!(
                "detail-move-space-short",
                drive = drive.as_str(),
                free = free_gb.to_string(),
                needed = needed_gb.to_string(),
                release = release.as_str()
            ),
            CheckDetail::SpaceUnknown { error } => t!("detail-move-space-unknown", error = error),
            CheckDetail::UpdateSourceMicrosoft => t!("detail-move-update-source-ok"),
            CheckDetail::UpdateSourceManaged { release } => {
                t!("detail-move-update-source-managed", release = release.as_str())
            }
        }
    }
}

/// Windows 11 hardware a PC lacks, by the worker's names (`tpm`, `uefi`), as
/// a list; a name this build doesn't know is left out.
pub fn hardware_list<S: AsRef<str>>(missing: &[S]) -> String {
    let names: Vec<String> = missing
        .iter()
        .filter_map(|part| match part.as_ref().trim() {
            "tpm" => Some(t!("hardware-tpm")),
            "uefi" => Some(t!("hardware-uefi")),
            _ => None,
        })
        .collect();
    join_and(&names)
}

impl Protection {
    /// The switch's name as Windows Security shows it.
    pub fn title(self) -> String {
        match self {
            Protection::TamperProtection => t!("protection-tamper"),
            Protection::RealTimeProtection => t!("protection-realtime"),
            Protection::CloudDelivered => t!("protection-cloud"),
            Protection::SampleSubmission => t!("protection-samples"),
        }
    }

    /// Why the switch has to be off while Atlas installs.
    pub fn why(self) -> String {
        match self {
            Protection::TamperProtection => t!("protection-tamper-why"),
            Protection::RealTimeProtection => t!("protection-realtime-reason"),
            Protection::CloudDelivered => t!("protection-cloud-reason"),
            Protection::SampleSubmission => t!("protection-samples-why"),
        }
    }
}

/// "2 still on", "1 still on, 1 can't be read", "All off".
pub fn security_summary(counts: &SwitchCounts) -> String {
    let mut parts: Vec<String> = Vec::new();
    if counts.on > 0 {
        parts.push(t!("security-count-still-on", count = counts.on));
    }
    if counts.unknown > 0 {
        parts.push(t!("security-count-unreadable", count = counts.unknown));
    }
    let mut iter = parts.into_iter();
    match iter.next() {
        None => t!("security-all-off"),
        Some(first) => iter.fold(first, |acc, next| t!("security-count-join", a = acc, b = next)),
    }
}

/// Why Microsoft Defender isn't on this PC, so the Windows Security step has
/// no switches to turn off. Only Atlas's NoDefender package counts as Atlas
/// having removed it; none of them stops the step.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DefenderAbsence {
    /// Atlas's package removed it, and this installation brings it back.
    Restore,
    /// Atlas's package removed it, and it stays removed.
    Removed,
    /// Atlas didn't remove it, and the user chose to keep it, which Atlas
    /// can't do.
    Missing,
    /// Atlas didn't remove it, and the user chose to remove it.
    Absent,
}

impl DefenderAbsence {
    /// The step's bar: its title, then its message.
    pub fn banner(self) -> (String, String) {
        match self {
            DefenderAbsence::Restore => {
                (t!("security-banner-restore-title"), t!("security-restore-nothing-to-turn-off"))
            }
            DefenderAbsence::Removed => {
                (t!("security-banner-removed-title"), t!("security-nothing-to-turn-off"))
            }
            DefenderAbsence::Missing => {
                (t!("security-banner-missing-title"), t!("security-banner-missing-message"))
            }
            DefenderAbsence::Absent => {
                (t!("security-banner-absent-title"), t!("security-nothing-to-turn-off"))
            }
        }
    }
}

impl ProtectionReminder {
    /// What to turn back on, naming the switches as Windows Security does,
    /// or that Defender is missing.
    pub fn message(&self) -> String {
        if self.missing {
            return t!("defender-missing-message");
        }
        let names: Vec<String> = self.switches.iter().map(|switch| switch.title()).collect();
        let switches = join_and(&names);
        // Whether the setup was left or the install kept Defender, the
        // title says what to do and the message what is still off.
        if self.unreadable {
            t!("home-security-reminder-unreadable-message", switches = switches)
        } else {
            t!("security-switches-still-off", switches = switches, count = names.len())
        }
    }
}

/// Why a report wasn't sent, and what to do instead.
pub fn report_failure(problem: SendProblem) -> String {
    match problem {
        SendProblem::Retry => t!("report-not-sent-retry"),
        SendProblem::Busy => t!("report-not-sent-busy"),
        SendProblem::Outdated => t!("report-not-sent-outdated"),
        SendProblem::Diagnostics => t!("report-not-sent-diagnostics"),
    }
}

/// What a finished attempt's advice depends on besides its outcome.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct AttemptFacts {
    /// How far the install got.
    pub phase: Phase,
    /// A retry of an install an earlier attempt already began applying:
    /// stopping early no longer means nothing changed.
    pub resumed: bool,
    /// It stopped on the error the attempt before it stopped on.
    pub repeated: bool,
    /// There are no Defender protections left to turn back on (see
    /// [`AppModel::defender_removed`](crate::model::AppModel::defender_removed)).
    pub defender_removed: bool,
    /// The apps Windows wouldn't remove, as the installer names them.
    pub unremoved_apps: Vec<String>,
}

impl InstallOutcome {
    pub fn title(self) -> String {
        match self {
            InstallOutcome::Succeeded => t!("outcome-succeeded-title"),
            InstallOutcome::Lost => t!("outcome-lost-title"),
            _ => t!("outcome-failed-title"),
        }
    }

    /// The result bar's title: an installer that never started, or stopped
    /// before changing anything for want of permission, a requirement or
    /// current updates, didn't "finish" anything, unless an earlier attempt
    /// had already begun.
    pub fn heading(self, resumed: bool) -> String {
        match self {
            InstallOutcome::NotStarted | InstallOutcome::Failed(2 | 3) if !resumed => t!("preflight-title"),
            outcome if outcome.needs_preparation() && !resumed => t!("preflight-title"),
            _ => self.title(),
        }
    }

    /// What happened, then what to do next, given how far the install got
    /// and what else is known about the attempt (see [`AttemptFacts`]), in
    /// two sentences at most. The result's button is the next step, so the
    /// words never name it; the installer's own error is behind Show details.
    pub fn advice(self, facts: &AttemptFacts) -> String {
        let (resumed, removed) = (facts.resumed, facts.defender_removed);
        let early = facts.phase < Phase::Applying;
        match self {
            InstallOutcome::Succeeded => t!("restart-needed"),
            InstallOutcome::Failed(2) if resumed && early => t!("result-requirements-resumed"),
            InstallOutcome::Failed(2) => t!("result-requirements"),
            InstallOutcome::Failed(3) if resumed && early => t!("result-not-elevated-resumed"),
            InstallOutcome::Failed(3) => t!("result-not-elevated"),
            outcome if outcome.needs_preparation() && resumed => t!("result-preparation-stale-resumed"),
            outcome if outcome.needs_preparation() => t!("result-preparation-stale"),
            // The same error again: another identical attempt won't get further.
            InstallOutcome::Failed(_) if facts.repeated => repeated_failure(facts),
            InstallOutcome::Failed(_) | InstallOutcome::NotStarted if resumed && early => {
                if removed {
                    t!("result-failed-resumed-defender-removed")
                } else {
                    t!("result-failed-resumed")
                }
            }
            InstallOutcome::Failed(_) => match facts.phase {
                Phase::Preflight => t!("result-failed-preflight"),
                Phase::Staging => t!("result-failed-staging"),
                Phase::Applying | Phase::Done if removed => t!("result-failed-applying-defender-removed"),
                Phase::Applying | Phase::Done => t!("result-failed-applying"),
            },
            InstallOutcome::NotStarted => t!("result-not-started"),
            InstallOutcome::Lost if removed => t!("result-lost-defender-removed"),
            InstallOutcome::Lost => t!("result-lost"),
        }
    }
}

/// A failure on the error the attempt before stopped on: it names the apps
/// Windows wouldn't remove, when that was the error, and leads to a report
/// rather than another try.
fn repeated_failure(facts: &AttemptFacts) -> String {
    let removed = facts.defender_removed;
    if facts.unremoved_apps.is_empty() {
        return if removed {
            t!("result-failed-repeated-defender-removed")
        } else {
            t!("result-failed-repeated")
        };
    }
    let apps = join_and(&facts.unremoved_apps);
    if removed {
        t!("result-failed-repeated-apps-defender-removed", apps = apps)
    } else {
        t!("result-failed-repeated-apps", apps = apps)
    }
}

impl InstallMode {
    /// "fresh install", inside a history line.
    pub fn history_label(self) -> String {
        match self {
            InstallMode::Fresh => t!("history-mode-fresh"),
            InstallMode::Upgrade => t!("history-mode-upgrade"),
            InstallMode::Reapply => t!("history-mode-reapply"),
            InstallMode::Rebase => t!("history-mode-rebase"),
            InstallMode::Unknown => t!("history-mode-unknown"),
        }
    }
}

impl ScreenKind {
    /// Short name, for the summary ("Microsoft Defender").
    pub fn title(self) -> String {
        match self {
            ScreenKind::UpdatePath => t!("step-options"),
            ScreenKind::Defender => t!("screen-defender-title"),
            ScreenKind::Mitigations => t!("screen-mitigations-title"),
            ScreenKind::Updates => t!("screen-updates-title"),
            ScreenKind::Keyboard => t!("screen-keyboard-title"),
            ScreenKind::Browser => t!("screen-browser-title"),
            ScreenKind::Power => t!("screen-power-title"),
            ScreenKind::Apps => t!("screen-apps-title"),
            ScreenKind::OptionalApps => t!("screen-optional-apps-title"),
            ScreenKind::ChooseOne => t!("screen-choose-one-title"),
            ScreenKind::Extras => t!("screen-extras-title"),
        }
    }

    /// The decision as a question ("Keep Microsoft Defender?").
    pub fn question(self) -> String {
        match self {
            ScreenKind::Defender => t!("screen-defender-question"),
            ScreenKind::Mitigations => t!("screen-mitigations-question"),
            ScreenKind::Updates => t!("screen-updates-question"),
            ScreenKind::Keyboard => t!("screen-keyboard-question"),
            // Its title is already the generic question; wrapping it would
            // read "Choose an option for Choose an option". The extras screen
            // asks no one question: each page on it has its own title.
            ScreenKind::UpdatePath | ScreenKind::ChooseOne | ScreenKind::Extras => self.title(),
            other => t!("screen-generic-question", title = other.title()),
        }
    }

    /// The short name in the middle of a sentence, as in "Change processor
    /// protections" or "Atlas's record for processor protections": lower
    /// case where the language lowers it, product names as they are.
    pub fn name(self) -> String {
        match self {
            ScreenKind::UpdatePath => t!("screen-update-path-name"),
            ScreenKind::Defender => t!("screen-defender-name"),
            ScreenKind::Mitigations => t!("screen-mitigations-name"),
            ScreenKind::Updates => t!("screen-updates-name"),
            ScreenKind::Keyboard => t!("screen-keyboard-name"),
            ScreenKind::Browser => t!("screen-browser-name"),
            ScreenKind::Power => t!("screen-power-name"),
            ScreenKind::Apps => t!("screen-apps-name"),
            ScreenKind::OptionalApps => t!("screen-optional-apps-name"),
            ScreenKind::ChooseOne => t!("screen-package-choice-name"),
            ScreenKind::Extras => t!("screen-extras-name"),
        }
    }

    pub fn learn_more(self) -> String {
        match self {
            ScreenKind::Defender => t!("learn-more-defender"),
            ScreenKind::Mitigations => t!("learn-more-mitigations"),
            ScreenKind::Updates => t!("learn-more-updates"),
            ScreenKind::Keyboard => t!("learn-more-keyboard"),
            ScreenKind::Browser => t!("learn-more-browser"),
            ScreenKind::Power => t!("learn-more-power"),
            ScreenKind::Apps => t!("learn-more-apps"),
            ScreenKind::OptionalApps => t!("learn-more-eclean"),
            ScreenKind::UpdatePath | ScreenKind::ChooseOne | ScreenKind::Extras => t!("learn-more-generic"),
        }
    }
}

/// What choosing an option means for the PC, in one line, for the options
/// this app knows by id. Other options show only their label.
pub fn option_consequence(id: &str) -> Option<String> {
    Some(match id {
        "defender-enable" => t!("consequence-defender-enable"),
        // Said as Your choices says what it costs, wherever it's listed.
        "defender-disable" => t!("cost-defender-disable"),
        "mitigations-default" => t!("consequence-mitigations-default"),
        "mitigations-disable" => t!("consequence-mitigations-disable"),
        "auto-updates-disable" => t!("consequence-auto-updates-disable"),
        "auto-updates-default" => t!("consequence-auto-updates-default"),
        "keyboard-shortcuts" => t!("consequence-keyboard-shortcuts"),
        "keyboard-selector" => t!("consequence-keyboard-selector"),
        "keyboard-single" => t!("consequence-keyboard-single"),
        "disable-hibernation" => t!("consequence-disable-hibernation"),
        "disable-power-saving" => t!("consequence-disable-power-saving"),
        "disable-core-isolation" => t!("consequence-disable-core-isolation"),
        "remove-snipping-tool" => t!("consequence-remove-snipping-tool"),
        "uninstall-edge" => t!("consequence-uninstall-edge"),
        "install-another-browser" => t!("consequence-install-another-browser"),
        "install-toolbox" => t!("consequence-install-toolbox"),
        "install-eclean" => t!("consequence-install-eclean"),
        _ => return None,
    })
}

/// App copy for a message keyed by a manifest id, in the current language,
/// or `None` when this app has no such message: the id is one a newer
/// package added.
fn known(message: &str) -> Option<String> {
    let catalog = super::current();
    catalog.has(message).then(|| catalog.format(message, &[]))
}

/// The label for an option where it's chosen: this app's own
/// (`package-option-<id>`) for an id it knows, or else `label`, the
/// manifest's English. A recommended answer says so.
pub fn option_label(id: &str, label: &str) -> String {
    known(&format!("package-option-{id}")).unwrap_or_else(|| label.trim().to_owned())
}

/// An option as an answer already given, in summaries, records and Home:
/// its label without the "(recommended)" a choice screen adds, from
/// `package-option-<id>-short` where the label carries one. Each language
/// words both forms, as where the note goes and how it's bracketed differ.
pub fn option_answer(id: &str, label: &str) -> String {
    known(&format!("package-option-{id}-short")).unwrap_or_else(|| option_label(id, label))
}

/// Whether Your choices shows answer `id`'s cost even though it's the
/// package's default. Installing updates yourself and letting Windows do it
/// each trade something off, and Atlas recommends neither, so both say what.
pub fn cost_shown_as_default(id: &str) -> bool {
    id == "auto-updates-disable"
}

/// The one line the install's Your choices shows under option `id`, where
/// its label doesn't say enough: for an answer to a question, what it costs,
/// which Your choices shows only under answers other than the package's
/// default (see [`cost_shown_as_default`]); for a check box, what ticking it does. Removing Microsoft Edge
/// deletes the user's Edge data on this PC, which has none before the
/// desktop exists, and then the label says enough. Options this app doesn't
/// know have none.
pub fn option_line(id: &str, before_desktop: bool) -> Option<String> {
    Some(match id {
        "defender-disable" => t!("cost-defender-disable"),
        "mitigations-disable" => t!("cost-mitigations-disable"),
        "auto-updates-disable" => t!("cost-auto-updates-disable"),
        "auto-updates-default" => t!("cost-auto-updates-default"),
        // With one layout there's nothing to switch, so the shortcuts cost nothing.
        "keyboard-selector" => t!("cost-keyboard-shortcuts-off"),
        "disable-hibernation" => t!("extra-disable-hibernation"),
        "disable-power-saving" => t!("extra-disable-power-saving"),
        "disable-core-isolation" => t!("extra-disable-core-isolation"),
        "remove-snipping-tool" => t!("consequence-remove-snipping-tool"),
        "uninstall-edge" if !before_desktop => t!("extra-uninstall-edge"),
        "install-toolbox" => t!("extra-install-toolbox"),
        "install-eclean" => t!("extra-install-eclean"),
        _ => return None,
    })
}

/// What a question of the install's Your choices says under its title, in
/// one sentence at most: this app's own for the choices it knows, nothing
/// where the question says enough, and otherwise the choice's description
/// (see [`choice_description`]). What every answer to the Defender question
/// turns off is in the Install step's details instead.
pub fn question_description(choice: &Choice) -> Option<String> {
    Some(match choice.id.as_str() {
        "defender" => t!("question-defender-description"),
        "mitigations" => t!("question-mitigations-description"),
        "auto-updates" => t!("question-auto-updates-description"),
        "browser" => t!("question-browser-description"),
        "keyboard" => return None,
        _ => return choice_description(choice),
    })
}

/// The caution a list of choices about to be applied to this PC shows under
/// an option that deletes the user's data.
pub fn data_caution(id: &str) -> Option<String> {
    (id == "uninstall-edge").then(|| t!("caution-uninstall-edge"))
}

/// The line under option `id` while choosing again, said instead of what the
/// option usually means, when the answer changes this PC, as the update's
/// Choices step applies it: Defender back where Atlas's package removed it,
/// a toggle Atlas recorded off, or VBS the PC shows off, turned back on,
/// Snipping Tool removed for good. `chosen` is whether the answer is chosen:
/// always for an option of a single choice, which is an answer of its own;
/// for a check box, whether it's ticked. `facts` is what the PC shows, as the
/// update reads it.
pub fn change_line(id: &str, chosen: bool, facts: &Facts) -> Option<String> {
    let record = |toggle: &str| facts.toggles.get(toggle).copied();
    Some(match id {
        "defender-enable" if facts.defender_package_installed() => t!("change-defender-enable"),
        // Every protection on stays on: Atlas never lowers them to Windows' default.
        "mitigations-default" if record("Mitigations") == Some(2) => t!("change-mitigations-all-on"),
        "mitigations-default" if record("Mitigations") == Some(0) => t!("change-mitigations-default"),
        "auto-updates-default" if record("AutomaticUpdates") == Some(0) => t!("change-auto-updates-default"),
        // Without Atlas's record of turning them off, clearing them changes nothing.
        "disable-hibernation" if !chosen && record("Hibernation") == Some(0) => t!("change-hibernation-on"),
        "disable-power-saving" if !chosen && record("PowerSaving") == Some(0) => t!("change-power-saving-on"),
        // VBS goes by what the PC shows where it could be read: a record
        // outlasts a change Windows Security or another tool made since.
        "disable-core-isolation"
            if !chosen && facts.core_isolation_off.unwrap_or(record("VbsState") == Some(0)) =>
        {
            t!("change-core-isolation-on")
        }
        "remove-snipping-tool" if chosen && facts.snipping_tool_removed() != Some(true) => {
            t!("change-remove-snipping-tool")
        }
        _ => return None,
    })
}

/// The Atlas Toolbox's name, which is the same in every language.
const TOOLBOX: &str = "Atlas Toolbox";

/// Why an update can't change an option, for the box Your choices shows
/// ticked and disabled. `label` names an option, such as a browser. Keeping
/// the choices fixes options only on screens it doesn't show, so it has no
/// words.
pub fn fixed_reason(fixed: &FixedChoice, label: impl Fn(&str) -> String) -> Option<String> {
    match fixed {
        FixedChoice::Kept => None,
        FixedChoice::EdgeRemoved => Some(t!("fixed-uninstall-edge")),
        FixedChoice::Installed(name) if name == "install-toolbox" => {
            Some(t!("fixed-installed", app = TOOLBOX))
        }
        FixedChoice::Installed(name) => Some(t!("fixed-installed", app = label(name))),
    }
}

/// What a choice is about: this app's own description
/// (`package-choice-<id>-description`) for a choice it describes, or else the
/// manifest's English, if it has any.
pub fn choice_description(choice: &Choice) -> Option<String> {
    known(&format!("package-choice-{}-description", choice.id))
        .or_else(|| Some(choice.description.trim().to_owned()).filter(|text| !text.is_empty()))
}
impl Notice {
    pub fn title(&self) -> String {
        match self {
            Notice::SettingsReset(_) => t!("notice-settings-reset-title"),
            Notice::SettingsNotSaved { .. } => t!("notice-settings-not-saved-title"),
            Notice::SessionUnreadable { .. } => t!("notice-session-unreadable-title"),
        }
    }

    /// What happened and what to do. The raw error, and the file it concerns,
    /// are [`Notice::details`], for Show details.
    pub fn message(&self) -> String {
        match self {
            Notice::SettingsReset(SettingsProblem::Unreadable { .. }) => {
                t!("notice-settings-unreadable-problem")
            }
            Notice::SettingsReset(SettingsProblem::DamagedKept { .. }) => {
                t!("notice-settings-damaged-kept-problem")
            }
            Notice::SettingsReset(SettingsProblem::Damaged { .. }) => t!("notice-settings-damaged-problem"),
            Notice::SettingsNotSaved { .. } => t!("notice-settings-not-saved-problem"),
            Notice::SessionUnreadable { .. } => t!("notice-session-unreadable-problem"),
        }
    }

    /// The raw error, after the path of the file it concerns where there is one.
    pub fn details(&self) -> String {
        match self {
            Notice::SettingsReset(
                SettingsProblem::Unreadable { error } | SettingsProblem::Damaged { error },
            )
            | Notice::SettingsNotSaved { error } => error.clone(),
            Notice::SettingsReset(SettingsProblem::DamagedKept { error, kept_as }) => {
                format!("{kept_as}\n{error}")
            }
            Notice::SessionUnreadable { error, record } => format!("{}\n{error}", record.display()),
        }
    }
}

impl InstallBlock {
    /// `bundled` is a tester build, which can't open another package.
    pub fn text(&self, bundled: bool) -> String {
        match self {
            InstallBlock::Unsupported { source, target: Some(target) } => {
                t!("install-source-unsupported", source = source, target = target)
            }
            InstallBlock::Unsupported { source, target: None } => {
                t!("install-source-unsupported-any", source = source)
            }
            InstallBlock::ResumeOther { target, .. } if bundled => {
                t!("install-source-resume-bundled", target = target)
            }
            InstallBlock::ResumeOther { target, downloads } => {
                t!("install-source-resume-package", target = target, folder = downloads.display().to_string())
            }
            InstallBlock::RecordUnreadable { error, record } => {
                t!("notice-session-unreadable-message", path = record.display().to_string(), error = error)
            }
            InstallBlock::Unknown => t!("install-source-unconfirmed"),
            InstallBlock::Windows { block, version, product, current, releases, ending } => match block {
                WindowsBlock::Edition => match ending {
                    Some(date) if chrono::Local::now().date_naive() > *date => t!(
                        "install-windows-edition-ended-update",
                        version = version.as_str(),
                        product = product.as_str(),
                        current = current.as_str()
                    ),
                    Some(date) => t!(
                        "install-windows-edition-until",
                        version = version.as_str(),
                        product = product.as_str(),
                        current = current.as_str(),
                        date = crate::i18n::fmt::day(*date)
                    ),
                    None => t!(
                        "install-windows-edition-only",
                        version = version.as_str(),
                        product = product.as_str()
                    ),
                },
                WindowsBlock::NoPath { .. } => {
                    t!("install-windows-reinstall", version = version.as_str(), releases = join_or(releases))
                }
                WindowsBlock::Preview => t!("detail-windows-preview"),
            },
        }
    }
}

/// Why a package needs a newer Atlas Manager, naming the version it asks
/// for when it names one; the Download Atlas Manager button goes beside it.
pub fn manager_outdated(required: Option<&str>) -> String {
    match required {
        Some(version) => t!("acquire-manager-update-needed", version = version),
        None => t!("acquire-manager-update-needed-any"),
    }
}

/// The same, naming the Atlas `version` whose package asks for it, as Get
/// ready and Home say it.
pub fn manager_needed(version: &str, required: Option<&str>) -> String {
    match required {
        Some(required) => t!("acquire-manager-update-required", version = version, required = required),
        None => t!("acquire-manager-update-required-any", version = version),
    }
}

impl AcquireProblem {
    /// `bundled` is a tester build, where the only remedy is Try again.
    pub fn text(&self, bundled: bool) -> String {
        match self {
            AcquireProblem::NoPackageAsset { version } => t!("acquire-no-asset", version = version),
            AcquireProblem::Unsupported { .. } | AcquireProblem::NotAPackage => t!("acquire-unsupported"),
            AcquireProblem::Incomplete { version } if bundled => {
                let error = crate::services::package::Incomplete { version: version.clone() }.to_string();
                t!("acquire-failed-bundled", error = error)
            }
            AcquireProblem::Incomplete { version } => t!("acquire-incomplete", version = version),
            AcquireProblem::ManagerOutdated { required } => manager_outdated(required.as_deref()),
            AcquireProblem::Stalled => t!("acquire-stalled"),
            AcquireProblem::Other { error } if bundled => t!("acquire-failed-bundled", error = error),
            AcquireProblem::Other { error } => t!("acquire-failed", error = error),
        }
    }
}

impl Preflight {
    /// The refusal bar's message. It names what needs attention, and the
    /// bar's button is the fix, so it says nothing of where that is; raw
    /// errors go behind Show details. `resumed` is a retry of an install an
    /// earlier attempt already began applying: a launch refused now changed
    /// nothing, but that one did. `missing` is the question the choices leave
    /// unanswered, when unusable choices are why and one is.
    pub fn text(&self, resumed: bool, missing: Option<ScreenKind>) -> String {
        match self {
            Preflight::InvalidOptions { .. } => match missing {
                Some(kind) => t!("preflight-choice-unanswered", choice = kind.name()),
                None => t!("preflight-choices-unusable"),
            },
            Preflight::Changed { checks, security } => {
                let mut sentences = Vec::new();
                if !checks.is_empty() {
                    let titles: Vec<String> = checks.iter().map(|(id, _)| id.title()).collect();
                    let count = titles.len();
                    sentences.push(t!("preflight-checks-changed", checks = join_and(&titles), count = count));
                }
                if let Some(counts) = security {
                    sentences.push(t!("preflight-security-changed", summary = security_summary(counts)));
                }
                sentences.join(" ")
            }
            Preflight::Busy => t!("preflight-busy-wait"),
            Preflight::TakenOver => t!("preflight-taken-over-start-over"),
            Preflight::RecordUnreadable { .. } => t!("preflight-record-unreadable-check"),
            Preflight::Refused { .. } if resumed => t!("preflight-not-started-resumed"),
            Preflight::Refused { .. } => t!("preflight-not-started"),
        }
    }
}

impl ElevationProblem {
    pub fn text(&self) -> String {
        match self {
            ElevationProblem::Declined => t!("elevation-declined"),
            ElevationProblem::DeclinedContinue => t!("elevation-declined-continue"),
            ElevationProblem::TakenOver => t!("elevation-taken-over"),
            ElevationProblem::DraftNotSaved { error } => t!("elevation-draft-not-saved", error = error),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::i18n::testing::english;
    use crate::model::ReminderReason;
    use crate::services::package::{ChoiceKind, ChoiceOption};
    use crate::services::security::SwitchCounts;

    #[test]
    fn security_summary_lists_only_nonzero_counts() {
        english(|| {
            assert_eq!(security_summary(&SwitchCounts { off: 4, on: 0, unknown: 0 }), t!("security-all-off"));
            assert_eq!(
                security_summary(&SwitchCounts { off: 2, on: 0, unknown: 2 }),
                t!("security-count-unreadable", count = 2u32)
            );
            assert_eq!(
                security_summary(&SwitchCounts { off: 2, on: 1, unknown: 1 }),
                t!(
                    "security-count-join",
                    a = t!("security-count-still-on", count = 1u32),
                    b = t!("security-count-unreadable", count = 1u32)
                )
            );
        });
    }

    /// An unrecognised required single choice is a ChooseOne screen. Its heading
    /// must not wrap its own title in the generic question.
    #[test]
    fn no_screen_question_repeats_its_own_title() {
        english(|| {
            assert_eq!(ScreenKind::ChooseOne.question(), ScreenKind::ChooseOne.title());
            for kind in [
                ScreenKind::Defender,
                ScreenKind::Mitigations,
                ScreenKind::Updates,
                ScreenKind::Browser,
                ScreenKind::Power,
                ScreenKind::Apps,
                ScreenKind::OptionalApps,
                ScreenKind::ChooseOne,
                ScreenKind::Extras,
            ] {
                let (title, question) = (kind.title(), kind.question());
                assert!(question.matches(title.as_str()).count() <= 1, "{kind:?}: {question}");
            }
        });
    }

    /// Edition advice names the editions the gate refuses, and gives only
    /// examples the gate accepts (see `SystemInfo::supported_edition`).
    #[test]
    fn edition_advice_matches_the_edition_gate() {
        let edition = |id: &str, installation: &str| {
            SystemInfo { edition_id: id.into(), installation_type: installation.into(), ..Default::default() }
                .supported_edition()
        };
        english(|| {
            let host = CheckDetail::EditionUnsupported.text(&SystemInfo::default());
            let iso = t!("iso-failed-edition");
            for (name, id) in
                [("Pro", "Professional"), ("Education", "Education"), ("Enterprise", "Enterprise")]
            {
                assert!(host.contains(name) && iso.contains(name), "{name} is not named");
                assert!(edition(id, "Client"), "{id} is named as supported but refused");
            }
            for (name, id) in [("Home", "Core"), ("LTSC", "EnterpriseS")] {
                assert!(host.contains(name) && iso.contains(name), "{name} is not named");
                assert!(!edition(id, "Client"), "{id} is named as unsupported but accepted");
            }
            assert!(host.contains("Server") && !edition("ServerStandard", "Server"));
        });
    }

    #[test]
    fn check_details_keep_raw_diagnostics_and_identifiers_verbatim() {
        english(|| {
            let missing = CheckDetail::BuildUnsupported { supported: vec![], actual: 26200 };
            assert_eq!(missing.text(&SystemInfo::default()), t!("detail-build-missing"));
            let system = SystemInfo {
                product_name: "Windows 11 Pro".into(),
                display_version: "25H2".into(),
                build: 26200,
                revision: 1234,
                ..Default::default()
            };
            assert!(system_description(&system).contains("26200.1234"));
            // Build numbers are identifiers: never grouped like quantities.
            let unsupported =
                CheckDetail::BuildUnsupported { supported: vec![26100, 26200], actual: 22631 }.text(&system);
            for build in ["26100", "26200", "22631"] {
                assert!(unsupported.contains(build), "{unsupported}");
            }
            assert!(!unsupported.contains("22,631"), "{unsupported}");
            // Update titles are for the log: the row counts them, and Windows Update lists them.
            let titles = vec!["KB1".into(), "KB2".into(), "KB3".into()];
            let pending = CheckDetail::UpdatesPending { titles }.text(&system);
            assert!(pending.contains('3') && !pending.contains("KB1"), "{pending}");
            let error = "0x80240438: la conexión falló";
            let unknown = CheckDetail::UpdatesUnknown { error: error.into() }.text(&system);
            assert!(unknown.contains(error), "{unknown}");
            let products = vec!["Avast".into(), "Norton".into()];
            let found = CheckDetail::AntivirusFound { products: products.clone() }.text(&system);
            assert!(found.contains(&join_list(&products)), "{found}");
        });
    }

    /// Which advice an outcome gets. A retry of an install an earlier attempt
    /// began applying must never say that nothing changed, however early it
    /// stops.
    #[test]
    fn install_advice_follows_outcome_phase_and_resume() {
        use InstallOutcome::{Failed, Lost, NotStarted};
        let facts = |phase, resumed| AttemptFacts { phase, resumed, ..AttemptFacts::default() };
        english(|| {
            let table = [
                (Failed(1), Phase::Preflight, false, "result-failed-preflight"),
                (Failed(1), Phase::Staging, false, "result-failed-staging"),
                (Failed(1), Phase::Applying, false, "result-failed-applying"),
                (Failed(1), Phase::Applying, true, "result-failed-applying"),
                (Failed(1), Phase::Preflight, true, "result-failed-resumed"),
                (Failed(1), Phase::Staging, true, "result-failed-resumed"),
                (NotStarted, Phase::Preflight, false, "result-not-started"),
                (NotStarted, Phase::Preflight, true, "result-failed-resumed"),
                (Failed(2), Phase::Preflight, false, "result-requirements"),
                (Failed(2), Phase::Applying, false, "result-requirements"),
                (Failed(2), Phase::Preflight, true, "result-requirements-resumed"),
                (Failed(3), Phase::Preflight, false, "result-not-elevated"),
                (Failed(3), Phase::Preflight, true, "result-not-elevated-resumed"),
                (Failed(5), Phase::Staging, false, "result-preparation-stale"),
                (Failed(5), Phase::Staging, true, "result-preparation-stale-resumed"),
                (Lost, Phase::Preflight, true, "result-lost"),
            ];
            // The bar's button is the next step, so no advice names a
            // button, and none runs past two sentences.
            let buttons = [
                t!("go-to-ready"),
                t!("common-restart-as-administrator"),
                t!("common-try-again"),
                t!("prepare-start"),
                t!("button-install"),
            ];
            for (outcome, phase, resumed, id) in table {
                let advice = outcome.advice(&facts(phase, resumed));
                assert_eq!(advice, crate::i18n::text(id, &[]), "{outcome:?} {phase:?} resumed: {resumed}");
                assert!(advice.matches(". ").count() <= 1, "{id}: {advice}");
                for button in &buttons {
                    assert!(!advice.contains(button.as_str()), "{id} names {button}: {advice}");
                }
            }
            // An unconfirmed result is not called a failure.
            assert_eq!(Lost.title(), t!("outcome-lost-title"));
            assert_ne!(Lost.title(), Failed(1).title());
            // An installer that never started didn't "finish": unless an earlier attempt changed things.
            assert_eq!(NotStarted.heading(false), t!("preflight-title"));
            assert_eq!(NotStarted.heading(true), t!("outcome-failed-title"));
            assert_eq!(Failed(1).heading(false), t!("outcome-failed-title"));
            // Nor did one stopped before changing anything, for want of
            // permission, a requirement or current updates.
            for stopped in [Failed(2), Failed(3), Failed(5)] {
                assert_eq!(stopped.heading(false), t!("preflight-title"), "{stopped:?}");
                assert_eq!(stopped.heading(true), t!("outcome-failed-title"), "{stopped:?}");
            }
            // A launch refused on a retry changed nothing itself, but an earlier attempt did.
            let refused = Preflight::Refused { error: "the log could not be created".into() };
            assert_eq!(refused.text(false, None), t!("preflight-not-started"));
            assert_eq!(refused.text(true, None), t!("preflight-not-started-resumed"));
        });
    }

    /// A refusal names what needs attention, never a button: the question
    /// the choices leave unanswered, the checks that changed and how the
    /// protection switches read now. Raw errors stay out of the words.
    #[test]
    fn a_refusal_names_what_needs_attention() {
        english(|| {
            let error = "Unknown or repeated Atlas option";
            let invalid = Preflight::InvalidOptions { error: error.into() };
            let named = invalid.text(false, Some(ScreenKind::Keyboard));
            // Named as it reads mid-sentence, as a choice the app has no name for is too.
            assert_eq!(named, t!("preflight-choice-unanswered", choice = ScreenKind::Keyboard.name()));
            assert_eq!(named, "Atlas needs your answer for keyboard languages.");
            let unknown = invalid.text(false, Some(ScreenKind::ChooseOne));
            assert_eq!(unknown, "Atlas needs your answer for a choice in the Atlas package.");
            assert_eq!(invalid.text(false, None), t!("preflight-choices-unusable"));
            let changed = Preflight::Changed {
                checks: vec![
                    (CheckId::Internet, CheckDetail::InternetMissing),
                    (CheckId::Power, CheckDetail::PowerUnknown),
                ],
                security: Some(SwitchCounts { off: 3, on: 1, unknown: 0 }),
            };
            let words = changed.text(false, None);
            let checks = join_and(&[CheckId::Internet.title(), CheckId::Power.title()]);
            assert!(
                words.starts_with(&t!("preflight-checks-changed", checks = checks, count = 2)),
                "{words}"
            );
            assert!(words.contains(&t!("security-count-still-on", count = 1u32)), "{words}");
            let unreadable = Preflight::RecordUnreadable { error: error.into() };
            let refused = Preflight::Refused { error: error.into() };
            for problem in
                [&invalid, &changed, &unreadable, &refused, &Preflight::Busy, &Preflight::TakenOver]
            {
                let words = problem.text(false, None);
                assert!(!words.contains(error), "{problem:?}");
                for button in
                    [t!("button-install"), t!("home-start-over"), t!("go-to-ready"), t!("ready-check-again")]
                {
                    assert!(!words.contains(&button), "{problem:?} names {button}: {words}");
                }
            }
        });
    }

    /// A retry that stops on the error the one before it stopped on doesn't
    /// invite a third identical try: it names the apps Windows kept, when
    /// that was the error, and points to a report. Outcomes with a remedy of
    /// their own keep it.
    #[test]
    fn a_failure_that_repeats_points_to_a_report_and_names_the_apps_windows_kept() {
        use InstallOutcome::Failed;
        let repeated = |phase, apps: &[&str]| AttemptFacts {
            phase,
            resumed: true,
            repeated: true,
            unremoved_apps: apps.iter().map(|app| app.to_string()).collect(),
            ..AttemptFacts::default()
        };
        english(|| {
            let report = t!("report-title");
            let general = Failed(1).advice(&repeated(Phase::Applying, &[]));
            assert_eq!(general, t!("result-failed-repeated"));
            let one = Failed(1).advice(&repeated(Phase::Applying, &["MSTeams"]));
            assert_eq!(one, t!("result-failed-repeated-apps", apps = "MSTeams"));
            let two = Failed(1).advice(&repeated(Phase::Applying, &["MSTeams", "Microsoft.Copilot"]));
            assert!(two.contains("MSTeams and Microsoft.Copilot"), "{two}");
            for advice in [&general, &one, &two] {
                assert!(advice.contains(&report), "{advice}");
                assert!(!advice.contains("You can try again"), "{advice}");
                assert!(advice.contains("protection switches"), "Defender is still there: {advice}");
                assert!(advice.matches(". ").count() <= 1, "{advice}");
            }
            // However early it stopped, the same error again is still a repeat.
            assert_eq!(Failed(1).advice(&repeated(Phase::Staging, &[])), general);
            // What a requirement, permission or preparation needs fixing is said as before.
            assert_eq!(Failed(2).advice(&repeated(Phase::Preflight, &[])), t!("result-requirements-resumed"));
            assert_eq!(Failed(3).advice(&repeated(Phase::Preflight, &[])), t!("result-not-elevated-resumed"));
            assert_eq!(
                Failed(5).advice(&repeated(Phase::Staging, &[])),
                t!("result-preparation-stale-resumed")
            );
            // A failure that is not a repeat still invites a retry.
            let first = AttemptFacts { repeated: false, ..repeated(Phase::Applying, &["MSTeams"]) };
            assert_eq!(Failed(1).advice(&first), t!("result-failed-applying"));
        });
    }

    /// Once Defender has no protections left to turn back on, no advice says
    /// to turn them back on, whatever the outcome; while it has, a failure
    /// that changed things does.
    #[test]
    fn no_advice_says_to_turn_protection_back_on_once_defender_is_removed() {
        use InstallOutcome::{Failed, Lost, NotStarted, Succeeded};
        english(|| {
            let security = "protection switches";
            for outcome in [Succeeded, Failed(1), Failed(2), Failed(3), Failed(5), NotStarted, Lost] {
                for phase in [Phase::Preflight, Phase::Staging, Phase::Applying, Phase::Done] {
                    for (resumed, repeated, apps) in [
                        (false, false, vec![]),
                        (true, false, vec![]),
                        (true, true, vec![]),
                        (true, true, vec!["MSTeams".into()]),
                    ] {
                        let facts = AttemptFacts {
                            phase,
                            resumed,
                            repeated,
                            defender_removed: true,
                            unremoved_apps: apps,
                        };
                        let advice = outcome.advice(&facts);
                        assert!(!advice.contains(security), "{outcome:?} {facts:?}: {advice}");
                    }
                }
            }
            let removed = |phase, resumed| AttemptFacts {
                phase,
                resumed,
                defender_removed: true,
                ..AttemptFacts::default()
            };
            assert_eq!(
                Failed(1).advice(&removed(Phase::Applying, false)),
                t!("result-failed-applying-defender-removed")
            );
            assert_eq!(
                Failed(1).advice(&removed(Phase::Staging, true)),
                t!("result-failed-resumed-defender-removed")
            );
            assert_eq!(Lost.advice(&removed(Phase::Applying, true)), t!("result-lost-defender-removed"));
            let repeated = AttemptFacts { repeated: true, ..removed(Phase::Applying, true) };
            assert_eq!(Failed(1).advice(&repeated), t!("result-failed-repeated-defender-removed"));
            let kept = AttemptFacts { unremoved_apps: vec!["MSTeams".into()], ..repeated };
            assert_eq!(
                Failed(1).advice(&kept),
                t!("result-failed-repeated-apps-defender-removed", apps = "MSTeams")
            );
            // Each one that stops offering protections still says what to do.
            for advice in [
                t!("result-failed-applying-defender-removed"),
                t!("result-failed-resumed-defender-removed"),
                t!("result-lost-defender-removed"),
            ] {
                assert!(advice.contains("try again"), "{advice}");
            }
            let present = AttemptFacts { phase: Phase::Applying, ..AttemptFacts::default() };
            for outcome in [Failed(1), Lost] {
                assert!(outcome.advice(&present).contains(security), "{outcome:?}");
            }
        });
    }

    #[test]
    fn install_blocks_name_the_target_and_offer_no_file_to_a_tester_build() {
        english(|| {
            let unsupported = |target: Option<&str>| InstallBlock::Unsupported {
                source: "0.4.0".into(),
                target: target.map(str::to_owned),
            };
            assert!(unsupported(Some("0.6.0")).text(false).contains("0.6.0"));
            assert!(!unsupported(None).text(false).contains("0.6.0"), "no target before a package is chosen");
            let resume = InstallBlock::ResumeOther { target: "0.6.1".into(), downloads: r"C:\D".into() };
            assert!(resume.text(false).contains("0.6.1") && resume.text(false).contains(r"C:\D"));
            assert!(!resume.text(true).contains(r"C:\D"), "a tester build can't open one");
            // The text never names the button that opens it: Open package file says that.
            assert!(!resume.text(false).contains(&t!("package-open-file")));
        });
    }

    #[test]
    fn preparation_failures_get_the_most_specific_advice_available() {
        english(|| {
            let activity = |code: Option<&str>, reason: Option<&str>| Activity {
                failure_message: Some("worker text".into()),
                error_code: code.map(str::to_owned),
                reason: reason.map(str::to_owned),
                ..Activity::default()
            };
            // A provider code the app knows comes first.
            let in_use = activity(Some(ERROR_PACKAGES_IN_USE), Some("store-timeout"));
            assert_eq!(
                preparation_failure(Some(&in_use), false),
                t!("prepare-close-app", app = t!("prepare-affected-app"))
            );
            let busy = activity(Some(WU_E_INSTALL_NOT_ALLOWED), None);
            assert_eq!(preparation_failure(Some(&busy), false), t!("prepare-install-busy"));
            // A damaged component store, which can stop any update, even on a fresh install.
            let damaged = activity(Some("0x80073712"), None);
            assert!(component_store_still_damaged(&damaged) && !component_store_unrepairable(&damaged));
            assert_eq!(preparation_failure(Some(&damaged), false), t!("prepare-components-damaged"));
            assert_eq!(preparation_failure_title(&damaged), Some(t!("prepare-components-damaged-title")));
            // Damage Windows records and can't repair stops a run before any
            // update; it outranks the error code a failed update gives.
            for unrepairable in [
                activity(None, Some(COMPONENT_STORE_UNREPAIRABLE)),
                activity(Some("0x80073712"), Some(COMPONENT_STORE_UNREPAIRABLE)),
            ] {
                assert!(component_store_unrepairable(&unrepairable));
                assert!(!component_store_still_damaged(&unrepairable));
                assert_eq!(
                    preparation_failure(Some(&unrepairable), false),
                    t!("prepare-components-unrepairable")
                );
                assert_eq!(
                    preparation_failure_title(&unrepairable),
                    Some(t!("prepare-components-unrepairable-title"))
                );
            }
            let other = activity(Some("0x80070005"), Some("store-timeout"));
            assert!(!component_store_still_damaged(&other) && !component_store_unrepairable(&other));
            let store = activity(None, Some("store-repair-failed"));
            assert_eq!(preparation_failure(Some(&store), false), t!("prepare-store-broken"));
            assert_eq!(preparation_failure_title(&store), Some(t!("prepare-store-broken-title")));
            assert_eq!(preparation_failure_title(&activity(None, Some("store-timeout"))), None);
            let battery = activity(None, Some("store-paused-battery"));
            assert_eq!(preparation_failure(Some(&battery), false), t!("prepare-failed-store-battery"));
            let unknown = activity(Some("0x80070005"), Some("a-newer-cause"));
            assert_eq!(preparation_failure(Some(&unknown), false), t!("prepare-failed-retry"));
            // A run that ended without a report is not described as a failure it cannot name.
            assert_eq!(preparation_failure(None, false), t!("prepare-unconfirmed"));
            assert_eq!(preparation_failure(None, true), t!("prepare-failed-retry"));
        });
    }

    #[test]
    fn every_cause_the_worker_names_has_its_own_advice() {
        english(|| {
            let worker = crate::services::preparation::WORKER;
            // Calls that pass a literal message, then the cause.
            let mut named: Vec<&str> = worker
                .split("New-PreparationFailure ")
                .skip(1)
                .filter_map(|call| {
                    let quote = call.chars().next().filter(|c| *c == '\'' || *c == '"')?;
                    let message = &call[1..];
                    let after = &message[message.find(quote)? + 1..];
                    after.trim_start().strip_prefix('\'')?.split('\'').next()
                })
                .collect();
            // The Store's own paused states, which the worker names apart from those calls.
            let paused = ["store-paused-battery", "store-paused-network"];
            for id in paused {
                assert!(worker.contains(&format!("'{id}'")), "{id} is not named by the worker");
            }
            named.extend(paused);
            assert!(named.len() >= 8, "{named:?}");
            for id in named {
                assert!(preparation_failure_reason(id).is_some(), "no advice for {id}");
            }
            assert_eq!(preparation_failure_reason("a-newer-cause"), None);
            // Why the worker refused a connection.
            for reason in ["limited", "metered", "offline", "roaming"] {
                assert!(worker.contains(&format!("'{reason}'")), "{reason} is not named by the worker");
            }
            assert_eq!(preparation_network(Some("limited")), t!("prepare-network-limited"));
            assert_eq!(preparation_network(Some("metered")), t!("prepare-network-metered"));
            for reason in [None, Some("offline"), Some("roaming")] {
                assert_eq!(preparation_network(reason), t!("prepare-network-unmetered"));
            }
        });
    }

    /// Every cause the update worker and its library name for a Windows
    /// move has words of its own, with the facts it carries filled in.
    #[test]
    fn every_cause_a_windows_move_names_has_its_own_words() {
        english(|| {
            use crate::services::preparation::{LIBRARY, WORKER};
            let mut named: Vec<&str> = [WORKER, LIBRARY]
                .iter()
                .flat_map(|source| source.split("New-AtlasTransitionFailure ").skip(1))
                .filter_map(|call| {
                    let quote = call.chars().next().filter(|c| *c == '\'' || *c == '"')?;
                    let message = &call[1..];
                    let after = &message[message.find(quote)? + 1..];
                    after.trim_start().strip_prefix('\'')?.split('\'').next()
                })
                .collect();
            named.sort_unstable();
            named.dedup();
            assert!(named.len() >= 15, "{named:?}");
            let words = TransitionWords { release: "26H2", current: "24H2", version: "0.6.0" };
            let missing = join_and(&[t!("hardware-tpm"), t!("hardware-uefi")]);
            let bits = t!("service-bits");
            let (release, current, version) =
                (("release", "26H2"), ("current", "24H2"), ("version", "0.6.0"));
            let setting = ("setting", "BITS");
            let disk = [("needed", "46"), ("drive", "D:"), ("free", "13")];
            // Each cause, the title and the message it gets and the facts each
            // shows, so a cause given another's words, or a fact in the wrong
            // place, fails.
            type Words<'a> = (&'a str, &'a [(&'a str, &'a str)]);
            type Expected<'a> = (&'a str, Words<'a>, Words<'a>);
            let expected: &[Expected] = &[
                (
                    "feature-not-offered",
                    ("windows-outcome-not-offered-title", &[release]),
                    ("windows-outcome-not-offered", &[current]),
                ),
                (
                    "feature-prerequisite",
                    ("windows-outcome-not-offered-title", &[release]),
                    ("windows-outcome-not-offered", &[current]),
                ),
                (
                    "feature-hardware",
                    ("windows-outcome-hardware-title", &[]),
                    ("windows-outcome-hardware", &[("missing", missing.as_str()), release]),
                ),
                (
                    "feature-hidden",
                    ("windows-outcome-hidden-title", &[release]),
                    ("windows-outcome-hidden", &[]),
                ),
                (
                    "feature-disk-space",
                    ("windows-outcome-disk-space-title", &[]),
                    ("windows-outcome-disk-space", &disk),
                ),
                (
                    "feature-servicing",
                    ("prepare-components-unrepairable-title", &[]),
                    ("prepare-components-unrepairable", &[]),
                ),
                (
                    "feature-managed",
                    ("windows-outcome-managed-title", &[]),
                    ("windows-outcome-managed", &[release]),
                ),
                (
                    "feature-policy",
                    ("windows-outcome-policy-title", &[]),
                    ("windows-outcome-policy", &[setting]),
                ),
                (
                    "feature-blocked",
                    ("windows-outcome-service-off-title", &[("service", bits.as_str())]),
                    ("windows-outcome-blocked-service", &[]),
                ),
                (
                    "feature-rolled-back",
                    ("windows-outcome-rollback-title", &[release]),
                    ("windows-outcome-rolled-back", &[current]),
                ),
                (
                    "feature-components-lost",
                    ("windows-outcome-components-lost-title", &[]),
                    ("windows-outcome-components-lost", &[version]),
                ),
                ("feature-build", ("windows-outcome-build-title", &[]), ("windows-outcome-build", &[])),
                ("feature-journal", ("windows-outcome-journal-title", &[]), ("windows-outcome-journal", &[])),
                ("feature-pin", ("windows-outcome-pin-title", &[]), ("windows-outcome-pin", &[setting])),
                (
                    "feature-terms",
                    ("windows-outcome-terms-title", &[]),
                    ("windows-outcome-terms", &[release]),
                ),
                (
                    "feature-failed",
                    ("windows-outcome-failed-title", &[release]),
                    ("windows-outcome-failed", &[current]),
                ),
            ];
            let words_of = |(message, facts): Words| {
                let args: Vec<(&str, crate::i18n::Arg)> =
                    facts.iter().map(|(name, value)| (*name, (*value).into())).collect();
                crate::i18n::text(message, &args)
            };
            for id in named {
                let activity = Activity {
                    reason: Some(id.to_owned()),
                    hardware: Some("tpm,uefi".into()),
                    drive: Some("D:".into()),
                    free_gb: Some("13".into()),
                    needed_gb: Some("46".into()),
                    setting: Some("BITS".into()),
                    ..Activity::default()
                };
                // Only putting the settings back names this one, and only
                // its raw text explains it.
                if id == "feature-restore" {
                    let error = format!("{id}: Atlas couldn't put back service.wuauserv.");
                    assert_eq!(restore_failure_cause(&error), None);
                    continue;
                }
                if id == "feature-install-active" {
                    assert_eq!(
                        restore_failure_cause(&format!("{id}: unfinished")).unwrap(),
                        t!("update-access-finish-install")
                    );
                    continue;
                }
                let outcome =
                    transition_outcome(&activity, &words).unwrap_or_else(|| panic!("no words for {id}"));
                let (_, title, body) = *expected
                    .iter()
                    .find(|(cause, ..)| *cause == id)
                    .unwrap_or_else(|| panic!("{id} needs its expected words in this test"));
                assert_eq!(outcome, Outcome { title: words_of(title), body: words_of(body) }, "{id}");
            }
            // A setting that isn't a service Windows names keeps its own name.
            let blocked = Activity {
                reason: Some("feature-blocked".into()),
                setting: Some("NoAutoUpdate".into()),
                ..Activity::default()
            };
            assert_eq!(
                transition_outcome(&blocked, &words).map(|outcome| outcome.body),
                Some(t!("windows-outcome-blocked", setting = "NoAutoUpdate"))
            );
            assert_eq!(
                transition_outcome(
                    &Activity { reason: Some("store-missing".into()), ..Activity::default() },
                    &words
                ),
                None
            );
            assert!(
                Activity { reason: Some("feature-prerequisite".into()), ..Activity::default() }.not_offered()
            );
            assert_eq!(restart_reason("feature-update"), t!("prepare-reason-feature-update"));
            assert_eq!(restart_reason("apprepository"), t!("prepare-reason-apprepository"));
        });
    }

    #[test]
    fn only_the_update_scan_can_be_confirmed_by_hand() {
        use crate::services::requirements::Verdict;
        english(|| {
            for id in CheckId::ALL {
                for verdict in [Verdict::Pass, Verdict::Warn, Verdict::Fail, Verdict::Unknown] {
                    let result = CheckResult { id, verdict, detail: CheckDetail::UpdatesNone };
                    assert_eq!(
                        result.acknowledgement().is_some(),
                        id == CheckId::PendingUpdates && verdict == Verdict::Unknown,
                        "{id:?} {verdict:?}"
                    );
                }
            }
        });
    }

    #[test]
    fn a_package_without_the_front_door_is_told_apart_by_its_version() {
        english(|| {
            let incomplete = AcquireProblem::Incomplete { version: "0.6.1".into() };
            // A damaged new package doesn't get the advice for an old one.
            let old = AcquireProblem::Unsupported { version: "0.6.1".into() };
            assert_ne!(incomplete.text(false), old.text(false));
            let retry = t!("common-try-again");
            assert!(incomplete.text(true).contains(&retry), "a tester build offers only Try again");
        });
    }

    /// A package for a newer Atlas Manager names the version it needs, when
    /// it gives one, as the Atlas Manager to download, so "it" can't be read
    /// as the package.
    #[test]
    fn a_package_for_a_newer_atlas_manager_names_the_version_and_the_download() {
        english(|| {
            let named = AcquireProblem::ManagerOutdated { required: Some("0.7.0".into()) };
            let unnamed = AcquireProblem::ManagerOutdated { required: None };
            for bundled in [false, true] {
                assert!(named.text(bundled).contains("Download Atlas Manager 0.7.0 or later and use it"));
                assert!(unnamed.text(bundled).contains("Download the latest Atlas Manager and use it"));
            }
            assert!(manager_needed("0.7.0", Some("0.7.1")).contains("download Atlas Manager 0.7.1 or later"));
            assert!(manager_needed("0.7.0", None).contains("download the latest Atlas Manager"));
        });
    }

    /// Every option and choice this app knows by id gets its own words in
    /// every language, whatever the manifest's English says; one it doesn't
    /// know shows the manifest's English.
    #[test]
    fn package_text_is_the_app_s_own_for_every_id_it_knows() {
        let choice = |id: &str, description: &str| Choice {
            id: id.into(),
            kind: ChoiceKind::Multiple,
            description: description.into(),
            learn_more: None,
            depends_on: None,
            options: vec![ChoiceOption { id: "x".into(), label: "X".into(), image: None, default: false }],
        };
        english(|| {
            let label = option_label("defender-disable", "Pause Defender");
            assert_eq!(label, t!("package-option-defender-disable"));
            assert_eq!(option_label("future-option", " New behaviour "), "New behaviour");
            assert!(option_consequence("defender-disable").is_some());
            assert_eq!(option_consequence("future-option"), None);
            assert_eq!(
                choice_description(&choice("defender", "Older words")),
                Some(t!("package-choice-defender-description"))
            );
            assert_eq!(choice_description(&choice("future", " New words ")).as_deref(), Some("New words"));
            assert_eq!(choice_description(&choice("future", "")), None);
            assert_eq!(
                choice_description(&choice("system", "")),
                None,
                "a known choice without a description"
            );
            // An answer already given doesn't say it was recommended; one
            // without a short form reads as where it's chosen.
            let manifest = crate::services::package::Manifest::builtin();
            for option in manifest.choices.iter().flat_map(|choice| &choice.options) {
                let answer = option_answer(&option.id, &option.label);
                assert!(!answer.contains("recommended"), "{}: {answer}", option.id);
                let label = option_label(&option.id, &option.label);
                assert!(answer == label || label.starts_with(&answer), "{}: {answer} / {label}", option.id);
            }
            assert_ne!(option_answer("defender-enable", ""), option_label("defender-enable", ""));
            assert_eq!(option_answer("future-option", " New behaviour "), "New behaviour");
        });
        crate::i18n::testing::with_chain(&["pl"], || {
            let translated = option_label("defender-enable", "Keep Microsoft Defender (recommended)");
            assert_ne!(translated, "Keep Microsoft Defender (recommended)");
            assert!(!translated.is_empty());
            assert_eq!(option_label("defender-enable", "Keep Defender on"), translated);
            // An option this app does not know keeps the manifest's words.
            assert_eq!(option_label("new-option", "Something new"), "Something new");
            let described = choice_description(&choice("browser", "Choose a browser to install.")).unwrap();
            assert_ne!(described, "Choose a browser to install.");
        });
    }
    #[test]
    fn the_consequence_table_covers_every_required_builtin_option() {
        let manifest = crate::services::package::Manifest::builtin();
        for choice in manifest
            .choices
            .iter()
            .filter(|choice| choice.kind == ChoiceKind::Single && choice.depends_on.is_none())
        {
            for option in &choice.options {
                assert!(option_consequence(&option.id).is_some(), "no consequence for {}", option.id);
            }
        }
    }

    /// Every answer of the built-in package's questions other than the
    /// default has a line that says what it costs, but one layout's, which
    /// costs nothing, and the install's Your choices says each in one
    /// sentence. Removing Edge says it deletes the user's data, which there's
    /// none of before the desktop exists.
    #[test]
    fn the_install_says_what_each_answer_costs_in_one_sentence() {
        let manifest = crate::services::package::Manifest::builtin();
        let one_sentence = |line: &str| {
            let stops = line.matches(". ").count() + line.matches("; ").count();
            stops == 0 && line.ends_with('.') && line.split_whitespace().count() <= 25
        };
        english(|| {
            for choice in &manifest.choices {
                if choice.kind == ChoiceKind::Single && choice.depends_on.is_none() {
                    for option in choice.options.iter().filter(|option| !option.default) {
                        let costs = option.id != "keyboard-single";
                        assert_eq!(option_line(&option.id, false).is_some(), costs, "{}", option.id);
                    }
                }
                for option in &choice.options {
                    if let Some(line) = option_line(&option.id, false) {
                        assert!(one_sentence(&line), "{}: {line}", option.id);
                    }
                }
                if let Some(description) = question_description(choice) {
                    assert!(one_sentence(&description), "{}: {description}", choice.id);
                }
            }
            assert!(option_line("uninstall-edge", false).is_some());
            assert_eq!(option_line("uninstall-edge", true), None);
            assert_eq!(option_line("install-another-browser", false), None, "the browser picker follows it");
            assert_eq!(option_line("future-option", false), None);
        });
    }

    /// Choosing again, an answer that changes this PC says what the update
    /// does there, as its Choices step applies it; one that leaves the PC as
    /// it is, or meets a record Atlas never wrote, says nothing new.
    #[test]
    fn choosing_again_says_what_an_answer_changes_on_this_pc() {
        let line = change_line;
        let records = |records: &[(&str, u32)]| Facts {
            toggles: records.iter().map(|(name, state)| ((*name).to_owned(), *state)).collect(),
            ..Facts::default()
        };
        let words = |id: &str| Some(crate::i18n::text(id, &[]));
        english(|| {
            let removed = Facts {
                packages: vec!["Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0".into()],
                ..Facts::default()
            };
            assert_eq!(line("defender-enable", true, &removed), words("change-defender-enable"));
            assert_eq!(line("defender-enable", true, &Facts::default()), None, "no Atlas package removed it");
            assert_eq!(line("defender-disable", true, &removed), None);

            let protections = |state| records(&[("Mitigations", state)]);
            assert_eq!(
                line("mitigations-default", true, &protections(0)),
                words("change-mitigations-default")
            );
            assert_eq!(
                line("mitigations-default", true, &protections(2)),
                words("change-mitigations-all-on")
            );
            assert_eq!(line("mitigations-default", true, &protections(1)), None, "already Windows' default");
            assert_eq!(
                line("mitigations-default", true, &Facts::default()),
                None,
                "no record, nothing applied"
            );
            assert_eq!(line("mitigations-disable", true, &protections(2)), None);
            let updates = |state| records(&[("AutomaticUpdates", state)]);
            assert_eq!(line("auto-updates-default", true, &updates(0)), words("change-auto-updates-default"));
            assert_eq!(line("auto-updates-default", true, &updates(1)), None);

            // A box cleared over Atlas's record turns the feature back on;
            // ticked, or with no record, it changes nothing.
            for (name, toggle, message) in [
                ("disable-hibernation", "Hibernation", "change-hibernation-on"),
                ("disable-power-saving", "PowerSaving", "change-power-saving-on"),
                ("disable-core-isolation", "VbsState", "change-core-isolation-on"),
            ] {
                let off = records(&[(toggle, 0)]);
                assert_eq!(line(name, false, &off), words(message), "{name}");
                assert_eq!(line(name, true, &off), None, "{name}");
                assert_eq!(line(name, false, &records(&[(toggle, 1)])), None, "{name}");
                assert_eq!(line(name, false, &Facts::default()), None, "{name}");
            }
            // VBS off whatever turned it off; on, whatever Atlas recorded.
            let vbs =
                |off, record: &[(&str, u32)]| Facts { core_isolation_off: Some(off), ..records(record) };
            let on_again = words("change-core-isolation-on");
            assert_eq!(line("disable-core-isolation", false, &vbs(true, &[])), on_again);
            assert_eq!(line("disable-core-isolation", false, &vbs(true, &[("VbsState", 1)])), on_again);
            assert_eq!(
                line("disable-core-isolation", false, &vbs(false, &[("VbsState", 0)])),
                None,
                "already on"
            );
            assert_eq!(line("disable-core-isolation", true, &vbs(true, &[])), None);

            // Removing Snipping Tool can't be undone, wherever it's still there.
            let apps = |families: &[&str]| Facts {
                appx: families.iter().map(|family| (*family).to_owned()).collect(),
                ..Facts::default()
            };
            let present =
                apps(&["Microsoft.ScreenSketch_8wekyb3d8bbwe", "Microsoft.WindowsCalculator_8wekyb3d8bbwe"]);
            let gone = apps(&["Microsoft.WindowsCalculator_8wekyb3d8bbwe"]);
            assert_eq!(line("remove-snipping-tool", true, &present), words("change-remove-snipping-tool"));
            assert_eq!(
                line("remove-snipping-tool", true, &Facts::default()),
                words("change-remove-snipping-tool")
            );
            assert_eq!(line("remove-snipping-tool", true, &gone), None);
            assert_eq!(line("remove-snipping-tool", false, &present), None);
            assert_eq!(line("install-eclean", true, &present), None);
        });
    }

    /// What an update can't undo says so, naming what is installed.
    #[test]
    fn a_fixed_choice_says_why_an_update_cannot_change_it() {
        let manifest = crate::services::package::Manifest::builtin();
        let label = |id: &str| option_label(id, manifest.option_label(id).unwrap());
        english(|| {
            assert_eq!(fixed_reason(&FixedChoice::EdgeRemoved, label), Some(t!("fixed-uninstall-edge")));
            assert_eq!(
                fixed_reason(&FixedChoice::Installed("install-toolbox".into()), label),
                Some(t!("fixed-installed", app = "Atlas Toolbox"))
            );
            let brave = fixed_reason(&FixedChoice::Installed("browser-brave".into()), label).unwrap();
            assert!(brave.starts_with("Brave is installed."), "{brave}");
            assert_eq!(fixed_reason(&FixedChoice::Kept, label), None);
        });
    }

    #[test]
    fn lists_end_with_the_language_s_and() {
        english(|| {
            let names = |items: &[&str]| items.iter().map(|item| item.to_string()).collect::<Vec<_>>();
            assert_eq!(join_and(&[]), "");
            assert_eq!(join_and(&names(&["Tamper Protection"])), "Tamper Protection");
            assert_eq!(join_and(&names(&["A", "B"])), "A and B");
            assert_eq!(join_and(&names(&["A", "B", "C"])), "A, B and C");
        });
    }

    #[test]
    fn a_protection_reminder_names_only_the_switches_it_read() {
        use crate::services::security::{Protection, SecurityStatus, Switch};
        let reading = SecurityStatus {
            tamper_protection: Switch::Off,
            real_time_protection: Switch::On,
            cloud_delivered: Switch::Off,
            sample_submission: Switch::Unknown,
            defender_present: true,
        };
        let reminder = |reason, status: &SecurityStatus| ProtectionReminder::from_reading(reason, status);
        english(|| {
            let kept = reminder(ReminderReason::KeptDefender, &reading).unwrap();
            assert_eq!(kept.switches, [Protection::CloudDelivered, Protection::TamperProtection]);
            let message = kept.message();
            assert!(message.contains("Cloud-delivered protection and Tamper Protection"), "{message}");
            assert!(message.starts_with("These are still off in Windows Security"), "{message}");
            assert!(!message.contains("Real-time") && !message.contains("sample"), "{message}");

            // Leaving a setup reads the same: the title says what to do.
            let left = reminder(ReminderReason::LeftFlow, &reading).unwrap().message();
            assert_eq!(left, message);

            // One switch reads as one, so languages can agree with it.
            let one = SecurityStatus { cloud_delivered: Switch::On, ..reading };
            let message = reminder(ReminderReason::KeptDefender, &one).unwrap().message();
            assert_eq!(message, "This is still off in Windows Security: Tamper Protection.");

            // Nothing reads off: what couldn't be read is named, without claiming it is off.
            let unread =
                SecurityStatus { tamper_protection: Switch::On, cloud_delivered: Switch::Unknown, ..reading };
            let soft = reminder(ReminderReason::KeptDefender, &unread).unwrap();
            assert!(soft.unreadable);
            let message = soft.message();
            assert!(message.contains("couldn't read"), "{message}");
            assert!(
                message.contains("Cloud-delivered protection and Automatic sample submission"),
                "{message}"
            );
            assert!(!message.contains("still off"), "{message}");
        });
        // Every switch on: nothing to remind about.
        let on = SecurityStatus {
            tamper_protection: Switch::On,
            real_time_protection: Switch::On,
            cloud_delivered: Switch::On,
            sample_submission: Switch::On,
            defender_present: true,
        };
        assert_eq!(reminder(ReminderReason::KeptDefender, &on), None);
        // Defender gone: leaving a flow, nothing was turned off to turn back
        // on; after an install that kept it, that it's missing.
        let gone = SecurityStatus { defender_present: false, ..reading };
        assert_eq!(reminder(ReminderReason::LeftFlow, &gone), None);
        let missing = reminder(ReminderReason::KeptDefender, &gone).unwrap();
        assert!(missing.missing && missing.switches.is_empty() && !missing.unreadable);
        english(|| assert_eq!(missing.message(), t!("defender-missing-message")));
    }
}
