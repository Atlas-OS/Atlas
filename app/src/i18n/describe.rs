//! Words for the app's semantic state. Services and the model keep facts
//! (a check's verdict and what it found, an outcome and the phase it ended
//! in, a notice's cause); these functions turn them into sentences in the
//! current language when a page renders, so switching language re-words
//! everything already on screen.
//!
//! Raw diagnostics (Windows error text, paths, versions, build numbers) are
//! passed through as text arguments and never translated or reformatted.

use crate::model::{
    AcquireProblem, ElevationProblem, InstallBlock, Notice, Preflight, ProtectionReminder, ReminderReason,
    RestartProblem, ScreenKind,
};
use crate::services::atlas_state::InstallMode;
use crate::services::installer::{InstallOutcome, Phase};
use crate::services::playbook::FeaturePage;
use crate::services::preparation::Activity;
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

/// What to do about a preparation run that failed. `failure` is the
/// worker's own report, if it wrote one; `has_error` says the app recorded
/// an error of its own. A run that ended with neither is not called a
/// failure it cannot describe.
pub fn preparation_failure(failure: Option<&Activity>, has_error: bool) -> String {
    let Some(failure) = failure else {
        return if has_error { t!("prepare-failed") } else { t!("prepare-ended-unconfirmed") };
    };
    match failure.error_code.as_deref() {
        Some(code) if code.eq_ignore_ascii_case(ERROR_PACKAGES_IN_USE) => {
            let app = failure.package_name.clone().unwrap_or_else(|| t!("prepare-affected-app"));
            t!("prepare-app-in-use", app = app)
        }
        Some(code) if code.eq_ignore_ascii_case(WU_E_INSTALL_NOT_ALLOWED) => t!("prepare-install-busy"),
        _ => failure
            .reason
            .as_deref()
            .and_then(preparation_failure_reason)
            .unwrap_or_else(|| t!("prepare-failed")),
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
        "store-repair-failed" => t!("prepare-failed-store-repair-failed"),
        "manual-updates" => t!("prepare-failed-manual-updates"),
        "windows-passes" => t!("prepare-failed-windows-passes"),
        _ => return None,
    })
}

/// What preparation did about Microsoft Store itself, said once it's done.
pub fn store_outcome(outcome: crate::services::preparation::StoreOutcome) -> String {
    use crate::services::preparation::StoreOutcome;
    match outcome {
        StoreOutcome::Updated => t!("prepare-store-updated"),
        StoreOutcome::Bootstrapped => t!("prepare-store-bootstrapped"),
        StoreOutcome::Repaired => t!("prepare-store-repaired"),
        StoreOutcome::SkippedRemoved => t!("prepare-store-skipped-removed"),
    }
}

/// The release names a move needs for its wording: where Windows goes
/// (`release`), where it is (`current`) and the Atlas version it's for.
pub struct TransitionWords<'a> {
    pub release: &'a str,
    pub current: &'a str,
    pub version: &'a str,
}

/// What a move between Windows releases ended with and what to do next, for
/// a cause the update worker names. `None` for any other failure.
pub fn transition_failure(failure: &Activity, words: &TransitionWords) -> Option<String> {
    let (release, current, version) = (words.release, words.current, words.version);
    let reason = failure.reason.as_deref()?;
    Some(match reason {
        // A missing monthly update is installed first; one Windows Update
        // doesn't offer yet is the same wait as the release itself.
        "feature-not-offered" | "feature-prerequisite" => {
            t!("prepare-failed-feature-not-offered", release = release, current = current)
        }
        "feature-hardware" => {
            let missing: Vec<String> = failure
                .hardware
                .as_deref()
                .unwrap_or_default()
                .split(',')
                .filter_map(|part| match part.trim() {
                    "tpm" => Some(t!("hardware-tpm")),
                    "uefi" => Some(t!("hardware-uefi")),
                    _ => None,
                })
                .collect();
            t!(
                "prepare-failed-feature-hardware",
                missing = join_list(&missing),
                release = release,
                current = current,
                version = version
            )
        }
        "feature-hidden" => t!("prepare-failed-feature-hidden", release = release),
        "feature-disk-space" => t!(
            "prepare-failed-feature-disk-space",
            needed = failure.needed_gb.clone().unwrap_or_default(),
            drive = failure.drive.clone().unwrap_or_default(),
            free = failure.free_gb.clone().unwrap_or_default()
        ),
        "feature-servicing" => t!("prepare-failed-feature-servicing"),
        "feature-managed" => t!("prepare-failed-feature-managed", release = release),
        "feature-policy" => {
            t!("prepare-failed-feature-policy", setting = failure.setting.clone().unwrap_or_default())
        }
        "feature-blocked" => {
            t!("prepare-failed-feature-blocked", setting = failure.setting.clone().unwrap_or_default())
        }
        "feature-rolled-back" => {
            t!("prepare-failed-feature-rolled-back", release = release, current = current)
        }
        "feature-components-lost" => t!("prepare-failed-feature-components-lost", version = version),
        "feature-build" => t!("prepare-failed-feature-build"),
        "feature-journal" => t!("prepare-failed-feature-journal"),
        "feature-pin" => {
            t!("prepare-failed-feature-pin", setting = failure.setting.clone().unwrap_or_default())
        }
        "feature-terms" => t!("prepare-failed-feature-terms", release = release),
        "feature-failed" => t!("prepare-failed-feature-failed", release = release, current = current),
        _ => return None,
    })
}

/// Why putting the Windows Update settings back failed, from the worker's error.
pub fn restore_failure(error: &str) -> String {
    restore_failure_cause(error).unwrap_or_else(|| t!("home-update-access-failed", error = error))
}

/// Why putting the settings back failed, for a cause the worker names; `None`
/// for any other error, which only the log explains.
pub fn restore_failure_cause(error: &str) -> Option<String> {
    match crate::services::preparation::operation_reason(error) {
        Some("feature-install-active") => Some(t!("home-update-access-install-active")),
        Some("feature-journal") => Some(t!("home-update-access-unreadable")),
        _ => None,
    }
}

/// Why preparation needs another connection, from the cause the worker
/// reported. Older workers report none.
pub fn preparation_network(reason: Option<&str>) -> String {
    match reason {
        Some("limited") => t!("prepare-network-limited"),
        Some("metered") => t!("prepare-network-metered"),
        _ => t!("prepare-network-needed"),
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
        }
    }

    /// Label for the button that opens the Settings page in `fix_target`.
    pub fn fix_label(self) -> Option<String> {
        Some(match self {
            CheckId::PendingUpdates | CheckId::PendingReboot => t!("check-fix-windows-update"),
            CheckId::ThirdPartyAntivirus => t!("check-fix-apps"),
            CheckId::Internet => t!("check-fix-network"),
            CheckId::Power => t!("check-fix-power"),
            CheckId::Activation => t!("check-fix-activation"),
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
            CheckDetail::UserAccountUnknown { error } => t!("detail-user-account-unknown", error = error),
            CheckDetail::BuildSupported => system_description(system),
            CheckDetail::EditionUnsupported => t!("detail-edition-unsupported"),
            CheckDetail::WindowsPreview => t!("detail-windows-preview"),
            CheckDetail::WindowsReleaseUnknown => t!("detail-windows-release-unknown"),
            CheckDetail::BuildTransition { current, release } => {
                t!("detail-build-transition", current = current.as_str(), release = release.as_str())
            }
            CheckDetail::BuildUnsupported { supported, actual } => {
                if supported.is_empty() {
                    return t!("detail-build-missing");
                }
                let builds: Vec<String> = supported.iter().map(u32::to_string).collect();
                t!("detail-build-unsupported", builds = join_or(&builds), build = actual.to_string())
            }
            CheckDetail::UpdatesNone => t!("detail-updates-none"),
            CheckDetail::UpdatesPending { titles } => {
                let shown: Vec<String> = titles.iter().take(2).cloned().collect();
                t!("detail-updates-pending", count = titles.len(), titles = shown.join("; "))
            }
            CheckDetail::UpdatesUnknown { error } => t!("detail-updates-unknown", error = error),
            CheckDetail::RebootNone => t!("detail-reboot-none"),
            CheckDetail::RebootPending { reasons } if reasons.is_empty() => t!("detail-reboot-pending"),
            CheckDetail::RebootPending { reasons } => {
                t!("detail-reboot-pending-reasons", reasons = restart_reasons(reasons))
            }
            CheckDetail::RebootFileRenames { files } => {
                let shown: Vec<String> = files.iter().take(3).cloned().collect();
                t!("detail-reboot-file-renames", files = join_list(&shown))
            }
            CheckDetail::RebootUnknown { error } => t!("detail-reboot-unknown", error = error),
            CheckDetail::AntivirusNone => t!("detail-antivirus-none"),
            CheckDetail::AntivirusFound { products } => {
                t!("detail-antivirus-found", products = join_list(products))
            }
            CheckDetail::AntivirusStale { products } => {
                t!("detail-antivirus-stale", products = join_list(products))
            }
            CheckDetail::AntivirusUnknown { error } => t!("detail-antivirus-unknown", error = error),
            CheckDetail::InternetOk => t!("detail-internet-ok"),
            CheckDetail::InternetMissing => t!("detail-internet-missing"),
            CheckDetail::PowerMains => t!("detail-power-mains"),
            CheckDetail::PowerBattery => t!("detail-power-battery"),
            CheckDetail::PowerUnknown => t!("detail-power-unknown"),
            CheckDetail::ActivationOk => t!("detail-activation-ok"),
            CheckDetail::ActivationMissing => t!("detail-activation-missing"),
            CheckDetail::ActivationNoLicence => t!("detail-activation-no-licence"),
            CheckDetail::ActivationUnknown { error } => t!("detail-activation-unknown", error = error),
        }
    }
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

    pub fn why(self) -> String {
        match self {
            Protection::TamperProtection => t!("protection-tamper-why"),
            Protection::RealTimeProtection => t!("protection-realtime-why"),
            Protection::CloudDelivered => t!("protection-cloud-why"),
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

impl ProtectionReminder {
    /// What to turn back on, naming the switches as Windows Security does,
    /// or that Defender is missing.
    pub fn message(&self) -> String {
        if self.missing {
            return t!("installed-defender-missing-message");
        }
        let names: Vec<String> = self.switches.iter().map(|switch| switch.title()).collect();
        let switches = join_and(&names);
        match (self.unreadable, self.reason) {
            (true, _) => t!("home-security-reminder-unreadable-message", switches = switches),
            (false, ReminderReason::LeftFlow) => t!("home-security-reminder-message", switches = switches),
            (false, ReminderReason::KeptDefender) => t!("installed-security-message", switches = switches),
        }
    }
}

/// Why a report wasn't sent, and what to do instead.
pub fn report_failure(problem: SendProblem) -> String {
    match problem {
        SendProblem::Retry => t!("report-failed"),
        SendProblem::Busy => t!("report-failed-busy"),
        SendProblem::Outdated => t!("report-failed-outdated"),
        SendProblem::Diagnostics => t!("report-failed-diagnostics"),
    }
}

impl InstallOutcome {
    pub fn title(self) -> String {
        match self {
            InstallOutcome::Succeeded => t!("outcome-succeeded-title"),
            InstallOutcome::Lost => t!("outcome-lost-title"),
            _ => t!("outcome-failed-title"),
        }
    }

    /// The result bar's title: an installer that never started didn't
    /// "finish" anything, unless an earlier attempt had already begun.
    pub fn heading(self, resumed: bool) -> String {
        match self {
            InstallOutcome::NotStarted if !resumed => t!("preflight-title"),
            _ => self.title(),
        }
    }

    /// What the user should do next, given how far the install got.
    /// `resumed` is a retry of an install an earlier attempt already began
    /// applying: stopping early no longer means nothing changed.
    pub fn advice(self, phase: Phase, resumed: bool) -> String {
        let early = phase < Phase::Applying;
        match self {
            InstallOutcome::Succeeded => t!("restart-needed"),
            InstallOutcome::Failed(2) if resumed && early => t!("outcome-requirements-resumed"),
            InstallOutcome::Failed(2) => t!("outcome-requirements"),
            InstallOutcome::Failed(3) if resumed && early => t!("outcome-not-elevated-resumed"),
            InstallOutcome::Failed(3) => t!("outcome-not-elevated"),
            outcome if outcome.needs_preparation() && resumed => t!("outcome-preparation-stale-resumed"),
            outcome if outcome.needs_preparation() => t!("outcome-preparation-stale"),
            InstallOutcome::Failed(_) | InstallOutcome::NotStarted if resumed && early => {
                t!("outcome-failed-resumed")
            }
            InstallOutcome::Failed(_) => match phase {
                Phase::Preflight => t!("outcome-failed-preflight"),
                Phase::Staging => t!("outcome-failed-staging"),
                Phase::Applying | Phase::Done => t!("outcome-failed-applying"),
            },
            InstallOutcome::NotStarted => t!("outcome-not-started"),
            InstallOutcome::Lost => t!("outcome-lost"),
        }
    }
}

impl InstallMode {
    /// "Fresh install", for a detail row.
    pub fn label(self) -> String {
        match self {
            InstallMode::Fresh => t!("mode-fresh"),
            InstallMode::Upgrade => t!("mode-upgrade"),
            InstallMode::Reapply => t!("mode-reapply"),
            InstallMode::Rebase => t!("mode-rebase"),
            InstallMode::Unknown => t!("mode-unknown"),
        }
    }

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
            ScreenKind::ChooseOne | ScreenKind::Extras => self.title(),
            other => t!("screen-generic-question", title = other.title()),
        }
    }

    pub fn learn_more(self) -> String {
        match self {
            ScreenKind::Defender => t!("learn-more-defender"),
            ScreenKind::Mitigations => t!("learn-more-mitigations"),
            ScreenKind::Updates => t!("learn-more-updates"),
            ScreenKind::Keyboard => t!("learn-more-generic"),
            ScreenKind::Browser => t!("learn-more-browser"),
            ScreenKind::Power => t!("learn-more-power"),
            ScreenKind::Apps => t!("learn-more-apps"),
            ScreenKind::OptionalApps => t!("learn-more-eclean"),
            ScreenKind::ChooseOne | ScreenKind::Extras => t!("learn-more-generic"),
        }
    }
}

/// What choosing an option means for the PC, in one line, for the options
/// this app knows. Unknown options rely on the package's own text.
pub fn option_consequence(name: &str) -> Option<String> {
    Some(match name {
        "defender-enable" => t!("consequence-defender-enable"),
        "defender-disable" => t!("consequence-defender-disable"),
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

/// The manifest's exact English text for a `playbook-*` message id: the
/// baseline that decides whether app copy may replace package text. Never
/// shown.
pub(super) fn playbook_source(id: &str) -> Option<&'static str> {
    include_str!("../../i18n/playbook-source.ftl").lines().find_map(|line| {
        let (key, value) = line.split_once(" = ")?;
        (key == id).then_some(value)
    })
}

/// Whether `package_text` is the wording this app knows for `id`.
fn recognised(id: &str, package_text: &str) -> bool {
    playbook_source(id).is_some_and(|source| source.trim() == package_text.trim())
}

/// Use app copy only for recognised package wording. A reworded or unknown
/// option keeps its own text, in English as well as translated languages.
fn guarded(id: &str, package_text: &str) -> String {
    if recognised(id, package_text) {
        super::current().format(id, None, &[])
    } else {
        package_text.trim().to_owned()
    }
}

/// The label for an option, translated when this app knows it.
pub fn option_label(name: &str, package_text: &str) -> String {
    guarded(&format!("playbook-option-{name}"), package_text)
}

/// The consequence line for an option, only while its package text is the
/// wording this app knows.
pub fn known_option_consequence(name: &str, package_text: &str) -> Option<String> {
    recognised(&format!("playbook-option-{name}"), package_text).then(|| option_consequence(name)).flatten()
}

/// What an option means for the install on this PC, which has the user's
/// data: removing Microsoft Edge deletes its bookmarks, history and saved
/// passwords here. Before the desktop exists (an ISO's setup) there is no
/// data yet, so the general line applies, as on ISO creation's own pages.
pub fn known_install_consequence(name: &str, package_text: &str, before_desktop: bool) -> Option<String> {
    let recognised = recognised(&format!("playbook-option-{name}"), package_text);
    match name {
        "uninstall-edge" if recognised && !before_desktop => Some(t!("consequence-uninstall-edge-data")),
        _ => known_option_consequence(name, package_text),
    }
}

/// The caution a list of choices about to be applied to this PC shows under
/// an option that deletes the user's data, when its text is the wording this
/// app knows.
pub fn known_data_caution(name: &str, package_text: &str) -> Option<String> {
    (name == "uninstall-edge" && recognised(&format!("playbook-option-{name}"), package_text))
        .then(|| t!("caution-uninstall-edge"))
}

/// The one line playbook.conf repeats on every checkbox page. Only this
/// exact text is hidden; a package that says anything else, however it
/// starts, shows its own words.
const PAGE_BOILERPLATE: &[&str] =
    &["Select the options you would like to use, they can be changed in the Atlas folder later."];

pub fn is_page_boilerplate(text: &str) -> bool {
    PAGE_BOILERPLATE.contains(&text.trim())
}

/// The package's own description of a page, translated when this app knows
/// it, minus the boilerplate line every checkbox page repeats.
///
/// Option explanations are guarded separately by [`known_option_consequence`].
pub fn page_description(page: &FeaturePage) -> Option<String> {
    let text = page.description.trim();
    if text.is_empty() || is_page_boilerplate(text) {
        return None;
    }
    let first = page.options.first().map(|option| option.name.as_str()).unwrap_or_default();
    Some(guarded(&format!("playbook-page-{first}-description"), text))
}

impl Notice {
    pub fn title(&self) -> String {
        match self {
            Notice::SettingsReset(_) => t!("notice-settings-reset-title"),
            Notice::SettingsNotSaved { .. } => t!("notice-settings-not-saved-title"),
            Notice::SessionUnreadable { .. } => t!("notice-session-unreadable-title"),
        }
    }

    pub fn message(&self) -> String {
        match self {
            Notice::SettingsReset(problem) => match problem {
                SettingsProblem::Unreadable { error } => t!("notice-settings-unreadable", error = error),
                SettingsProblem::DamagedKept { error, kept_as } => {
                    t!("notice-settings-damaged-kept", file = kept_as, error = error)
                }
                SettingsProblem::Damaged { error } => t!("notice-settings-damaged", error = error),
            },
            Notice::SettingsNotSaved { error } => t!("notice-settings-not-saved", error = error),
            Notice::SessionUnreadable { error, record } => {
                t!("notice-session-unreadable-message", path = record.display().to_string(), error = error)
            }
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
                t!("install-source-resume", target = target, folder = downloads.display().to_string())
            }
            InstallBlock::RecordUnreadable { error, record } => {
                t!("notice-session-unreadable-message", path = record.display().to_string(), error = error)
            }
            InstallBlock::Unknown => t!("install-source-unknown"),
            InstallBlock::Windows { block, version, product, current, releases, ending } => match block {
                WindowsBlock::Edition => match ending {
                    Some(date) => t!(
                        "install-windows-edition-ending",
                        version = version.as_str(),
                        product = product.as_str(),
                        current = current.as_str(),
                        date = crate::i18n::fmt::day(*date)
                    ),
                    None => {
                        t!("install-windows-edition", version = version.as_str(), product = product.as_str())
                    }
                },
                WindowsBlock::NoPath { .. } => {
                    t!("install-windows-no-path", version = version.as_str(), releases = join_or(releases))
                }
                WindowsBlock::Preview => t!("detail-windows-preview"),
            },
        }
    }
}

impl AcquireProblem {
    /// `bundled` is a tester build, where the only remedy is Try again.
    pub fn text(&self, bundled: bool) -> String {
        match self {
            AcquireProblem::NoPlaybookAsset { version } => t!("acquire-no-asset", version = version),
            AcquireProblem::Unsupported { version } => t!("acquire-unsupported", version = version),
            AcquireProblem::Incomplete { version } if bundled => {
                let error = crate::services::playbook::Incomplete { version: version.clone() }.to_string();
                t!("acquire-failed-bundled", error = error)
            }
            AcquireProblem::Incomplete { version } => t!("acquire-incomplete", version = version),
            AcquireProblem::Stalled => t!("acquire-stalled"),
            AcquireProblem::Other { error } if bundled => t!("acquire-failed-bundled", error = error),
            AcquireProblem::Other { error } => t!("acquire-failed", error = error),
        }
    }
}

impl Preflight {
    /// `resumed` is a retry of an install an earlier attempt already began
    /// applying: a launch refused now changed nothing, but that one did.
    pub fn text(&self, system: &SystemInfo, resumed: bool) -> String {
        match self {
            Preflight::InvalidOptions { error } => t!("preflight-invalid-options", error = error),
            Preflight::Changed { checks, security } => {
                let mut problems: Vec<String> = checks
                    .iter()
                    .map(|(id, detail)| {
                        t!("preflight-problem", title = id.title(), detail = detail.text(system))
                    })
                    .collect();
                if let Some(counts) = security {
                    problems.push(t!("preflight-security", summary = security_summary(counts)));
                }
                t!("preflight-changed", problems = problems.join(" "))
            }
            Preflight::Busy => t!("preflight-busy"),
            Preflight::TakenOver => t!("preflight-taken-over"),
            Preflight::RecordUnreadable { error } => t!("preflight-record-unreadable", error = error),
            Preflight::Refused { error } if resumed => t!("preflight-refused-resumed", error = error),
            Preflight::Refused { error } => t!("preflight-refused", error = error),
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

impl RestartProblem {
    pub fn text(&self) -> String {
        match self {
            RestartProblem::Start { error } => t!("restart-start-failed", error = error),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::i18n::testing::english;
    use crate::services::playbook::{FeatureOption, PageKind};
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

    /// An unrecognised required radio page is a ChooseOne screen. Its heading
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
            let titles = vec!["KB1".into(), "KB2".into(), "KB3".into()];
            let pending = CheckDetail::UpdatesPending { titles }.text(&system);
            assert!(pending.contains("KB1; KB2") && !pending.contains("KB3"), "{pending}");
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
        english(|| {
            let table = [
                (Failed(1), Phase::Preflight, false, "outcome-failed-preflight"),
                (Failed(1), Phase::Staging, false, "outcome-failed-staging"),
                (Failed(1), Phase::Applying, false, "outcome-failed-applying"),
                (Failed(1), Phase::Applying, true, "outcome-failed-applying"),
                (Failed(1), Phase::Preflight, true, "outcome-failed-resumed"),
                (Failed(1), Phase::Staging, true, "outcome-failed-resumed"),
                (NotStarted, Phase::Preflight, false, "outcome-not-started"),
                (NotStarted, Phase::Preflight, true, "outcome-failed-resumed"),
                (Failed(2), Phase::Preflight, false, "outcome-requirements"),
                (Failed(2), Phase::Applying, false, "outcome-requirements"),
                (Failed(2), Phase::Preflight, true, "outcome-requirements-resumed"),
                (Failed(3), Phase::Preflight, false, "outcome-not-elevated"),
                (Failed(3), Phase::Preflight, true, "outcome-not-elevated-resumed"),
                (Failed(5), Phase::Staging, false, "outcome-preparation-stale"),
                (Failed(5), Phase::Staging, true, "outcome-preparation-stale-resumed"),
                (Lost, Phase::Preflight, true, "outcome-lost"),
            ];
            for (outcome, phase, resumed, id) in table {
                assert_eq!(
                    outcome.advice(phase, resumed),
                    crate::i18n::text(id, &[]),
                    "{outcome:?} {phase:?} resumed: {resumed}"
                );
            }
            // Out-of-date preparation sends the user back to Get ready, whose
            // button then reads prepare-start; other failures don't.
            let button = t!("prepare-start");
            assert!(Failed(5).advice(Phase::Staging, false).contains(&button));
            assert!(Failed(5).advice(Phase::Staging, true).contains(&button));
            assert!(!Failed(1).advice(Phase::Staging, false).contains(&button));
            // An unconfirmed result is not called a failure.
            assert_eq!(Lost.title(), t!("outcome-lost-title"));
            assert_ne!(Lost.title(), Failed(1).title());
            // An installer that never started didn't "finish": unless an earlier attempt changed things.
            assert_eq!(NotStarted.heading(false), t!("preflight-title"));
            assert_eq!(NotStarted.heading(true), t!("outcome-failed-title"));
            assert_eq!(Failed(1).heading(false), t!("outcome-failed-title"));
            // Neither names a button that may be unavailable.
            for outcome in [NotStarted, Lost] {
                assert!(!outcome.advice(Phase::Preflight, false).contains(&t!("common-try-again")));
            }
            // A launch refused on a retry changed nothing itself, but an earlier attempt did.
            let error = "the log could not be created";
            let refused = Preflight::Refused { error: error.into() };
            assert_eq!(refused.text(&SystemInfo::default(), false), t!("preflight-refused", error = error));
            assert_eq!(
                refused.text(&SystemInfo::default(), true),
                t!("preflight-refused-resumed", error = error)
            );
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
            let open = t!("package-open-file");
            let resume = InstallBlock::ResumeOther { target: "0.6.1".into(), downloads: r"C:\D".into() };
            assert!(resume.text(false).contains(&open) && resume.text(false).contains(r"C:\D"));
            assert!(!resume.text(true).contains(&open), "a tester build can't open one");
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
                t!("prepare-app-in-use", app = t!("prepare-affected-app"))
            );
            let busy = activity(Some(WU_E_INSTALL_NOT_ALLOWED), None);
            assert_eq!(preparation_failure(Some(&busy), false), t!("prepare-install-busy"));
            let battery = activity(None, Some("store-paused-battery"));
            assert_eq!(preparation_failure(Some(&battery), false), t!("prepare-failed-store-battery"));
            let unknown = activity(Some("0x80070005"), Some("a-newer-cause"));
            assert_eq!(preparation_failure(Some(&unknown), false), t!("prepare-failed"));
            // A run that ended without a report is not described as a failure it cannot name.
            assert_eq!(preparation_failure(None, false), t!("prepare-ended-unconfirmed"));
            assert_eq!(preparation_failure(None, true), t!("prepare-failed"));
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
            // The Store's own paused states.
            named.extend(["store-paused-battery", "store-paused-network"]);
            assert!(named.len() >= 8, "{named:?}");
            for id in named {
                assert!(worker.contains(&format!("'{id}'")), "{id} is not named by the worker");
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
                assert_eq!(preparation_network(reason), t!("prepare-network-needed"));
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
            for id in named {
                let activity = Activity {
                    reason: Some(id.to_owned()),
                    hardware: Some("tpm,uefi".into()),
                    drive: Some("C:".into()),
                    free_gb: Some("3".into()),
                    needed_gb: Some("6".into()),
                    setting: Some("BITS".into()),
                    ..Activity::default()
                };
                // Only putting the settings back names this one.
                if id == "feature-restore" {
                    let error = format!("{id}: Atlas couldn't put back service.wuauserv.");
                    assert_eq!(
                        restore_failure(&error),
                        t!("home-update-access-failed", error = error.as_str())
                    );
                    continue;
                }
                if id == "feature-install-active" {
                    assert_eq!(
                        restore_failure(&format!("{id}: unfinished")),
                        t!("home-update-access-install-active")
                    );
                    continue;
                }
                let text =
                    transition_failure(&activity, &words).unwrap_or_else(|| panic!("no words for {id}"));
                assert!(!text.contains('{'), "{id}: {text}");
            }
            let hardware = Activity {
                reason: Some("feature-hardware".into()),
                hardware: Some("tpm,uefi".into()),
                ..Activity::default()
            };
            let text = transition_failure(&hardware, &words).unwrap();
            assert!(text.contains("TPM 2.0") && text.contains("UEFI firmware"), "{text}");
            let space = Activity {
                reason: Some("feature-disk-space".into()),
                drive: Some("D:".into()),
                free_gb: Some("3".into()),
                needed_gb: Some("6".into()),
                ..Activity::default()
            };
            let text = transition_failure(&space, &words).unwrap();
            assert!(text.contains("D:") && text.contains('3') && text.contains('6'), "{text}");
            assert_eq!(
                transition_failure(
                    &Activity { reason: Some("store-missing".into()), ..Activity::default() },
                    &words
                ),
                None
            );
            assert!(
                Activity { reason: Some("feature-prerequisite".into()), ..Activity::default() }.not_offered()
            );
            assert_eq!(restart_reason("feature-update"), t!("prepare-reason-feature-update"));
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

    #[test]
    fn playbook_text_is_translated_only_when_it_matches_the_source() {
        english(|| {
            let label = option_label("defender-disable", "Disable Defender");
            assert_eq!(label, t!("playbook-option-defender-disable"));
            assert_ne!(label, "Disable Defender");
            assert!(known_option_consequence("defender-disable", "Disable Defender").is_some());
            assert_eq!(known_option_consequence("defender-disable", "Pause Defender"), None);
            assert_eq!(option_label("defender-disable", "Pause Defender"), "Pause Defender");
            assert_eq!(known_option_consequence("future-option", "New behaviour"), None);
        });
        crate::i18n::testing::with_chain(&["pl"], || {
            let translated = option_label("defender-enable", "Enable Defender (recommended)");
            assert_ne!(translated, "Enable Defender (recommended)");
            assert!(!translated.is_empty());
            // A package that reworded the option keeps its own words.
            assert_eq!(option_label("defender-enable", "Keep Defender on"), "Keep Defender on");
            // An option this app does not know keeps its own words too.
            assert_eq!(option_label("new-option", "Something new"), "Something new");
            let mut page = FeaturePage {
                kind: PageKind::Checkbox,
                description:
                    "Select the options you would like to use, they can be changed in the Atlas folder later."
                        .into(),
                learn_more: None,
                depends_on: None,
                options: vec![FeatureOption {
                    name: "x".into(),
                    text: "X".into(),
                    image: None,
                    default: false,
                }],
            };
            assert_eq!(page_description(&page), None, "the exact boilerplate line is dropped");
            // Anything else that merely starts the same way is the package's
            // own text and must stay.
            page.description = "Select the options below. This change removes Microsoft Edge.".into();
            assert_eq!(
                page_description(&page).as_deref(),
                Some("Select the options below. This change removes Microsoft Edge.")
            );
        });
    }

    #[test]
    fn the_consequence_table_covers_every_required_builtin_option() {
        let manifest = crate::services::playbook::Manifest::builtin();
        for page in
            manifest.pages.iter().filter(|page| page.kind == PageKind::Radio && page.depends_on.is_none())
        {
            for option in &page.options {
                assert!(option_consequence(&option.name).is_some(), "no consequence for {}", option.name);
            }
        }
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
            assert!(message.contains("You kept Microsoft Defender"), "{message}");
            assert!(!message.contains("Real-time") && !message.contains("sample"), "{message}");

            let left = reminder(ReminderReason::LeftFlow, &reading).unwrap().message();
            assert!(left.contains("Atlas isn't installing anything"), "{left}");
            assert!(left.contains("Cloud-delivered protection and Tamper Protection"), "{left}");

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
        english(|| assert_eq!(missing.message(), t!("installed-defender-missing-message")));
    }
}
