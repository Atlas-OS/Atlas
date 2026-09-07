//! Words for the app's semantic state. Services and the model keep facts
//! (a check's verdict and what it found, an outcome and the phase it ended
//! in, a notice's cause); these functions turn them into sentences in the
//! current language when a page renders, so switching language re-words
//! everything already on screen.
//!
//! Raw diagnostics (Windows error text, paths, versions, build numbers) are
//! passed through as text arguments and never translated or reformatted.

use crate::model::{AcquireProblem, ElevationProblem, Notice, Preflight, RestartProblem, ScreenKind};
use crate::services::atlas_state::InstallMode;
use crate::services::installer::{InstallOutcome, Phase};
use crate::services::playbook::FeaturePage;
use crate::services::requirements::{CheckDetail, CheckId};
use crate::services::security::{Protection, SwitchCounts};
use crate::services::settings::SettingsProblem;
use crate::services::system::SystemInfo;
use crate::t;

/// Joins items with the language's list separator: "Brave, Firefox".
pub fn join_list(items: &[String]) -> String {
    let separator = t!("list-separator");
    items.join(&separator)
}

/// Joins alternatives: "26100 or 26200".
pub fn join_or(items: &[String]) -> String {
    let mut iter = items.iter();
    let Some(first) = iter.next() else { return String::new() };
    iter.fold(first.clone(), |acc, next| t!("list-or", a = acc, b = next))
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
            CheckId::Internet => t!("check-fix-network"),
            CheckId::Power => t!("check-fix-power"),
            CheckId::Activation => t!("check-fix-activation"),
            _ => return None,
        })
    }

    /// What the user confirms when a blocking check could not run.
    pub fn acknowledgement(self) -> String {
        match self {
            CheckId::PendingUpdates => t!("check-ack-updates"),
            CheckId::PendingReboot => t!("check-ack-reboot"),
            CheckId::Internet => t!("check-ack-internet"),
            _ => t!("check-ack-generic"),
        }
    }
}

impl CheckDetail {
    pub fn text(&self, system: &SystemInfo) -> String {
        match self {
            CheckDetail::AdministratorOk => t!("detail-admin-ok"),
            CheckDetail::AdministratorMissing => t!("detail-admin-missing"),
            CheckDetail::BuildSupported => system_description(system),
            CheckDetail::EditionUnsupported => t!("detail-edition-unsupported"),
            CheckDetail::WindowsPreview => t!("detail-windows-preview"),
            CheckDetail::WindowsReleaseUnknown => t!("detail-windows-release-unknown"),
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
            CheckDetail::RebootPending => t!("detail-reboot-pending"),
            CheckDetail::RebootUnknown { error } => t!("detail-reboot-unknown", error = error),
            CheckDetail::AntivirusNone => t!("detail-antivirus-none"),
            CheckDetail::AntivirusFound { products } => {
                t!("detail-antivirus-found", products = join_list(products))
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

impl InstallOutcome {
    pub fn title(self) -> String {
        match self {
            InstallOutcome::Succeeded => t!("outcome-succeeded-title"),
            InstallOutcome::Lost => t!("outcome-lost-title"),
            _ => t!("outcome-failed-title"),
        }
    }

    /// What the user should do next, given how far the install got.
    pub fn advice(self, phase: Phase) -> String {
        match self {
            InstallOutcome::Succeeded => t!("outcome-succeeded"),
            InstallOutcome::Failed(2) => t!("outcome-requirements"),
            InstallOutcome::Failed(3) => t!("outcome-not-elevated"),
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
            InstallMode::Unknown => t!("mode-unknown"),
        }
    }

    /// "fresh install", inside a history line.
    pub fn history_label(self) -> String {
        match self {
            InstallMode::Fresh => t!("history-mode-fresh"),
            InstallMode::Upgrade => t!("history-mode-upgrade"),
            InstallMode::Reapply => t!("history-mode-reapply"),
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
            ScreenKind::Extras => t!("screen-extras-question"),
            other => t!("screen-generic-question", title = other.title()),
        }
    }

    pub fn learn_more(self) -> String {
        match self {
            ScreenKind::Defender => t!("learn-more-defender"),
            ScreenKind::Mitigations => t!("learn-more-mitigations"),
            ScreenKind::Updates => t!("learn-more-updates"),
            ScreenKind::Browser => t!("learn-more-browser"),
            ScreenKind::Power => t!("learn-more-power"),
            ScreenKind::Apps => t!("learn-more-apps"),
            ScreenKind::OptionalApps => t!("learn-more-eclean"),
            ScreenKind::ChooseOne | ScreenKind::Extras => t!("learn-more-generic"),
        }
    }
}

/// What choosing an option means for the PC, in one line, for the options
/// this app knows. Unknown options rely on the playbook's own text.
pub fn option_consequence(name: &str) -> Option<String> {
    Some(match name {
        "defender-enable" => t!("consequence-defender-enable"),
        "defender-disable" => t!("consequence-defender-disable"),
        "mitigations-default" => t!("consequence-mitigations-default"),
        "mitigations-disable" => t!("consequence-mitigations-disable"),
        "auto-updates-disable" => t!("consequence-auto-updates-disable"),
        "auto-updates-default" => t!("consequence-auto-updates-default"),
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

/// Exact package wording, kept separate from editable interface copy.
/// These plain, single-line messages are checked against the built-in
/// manifest by the catalog gate. They are never displayed to the user.
pub(super) fn playbook_source(id: &str) -> Option<&'static str> {
    include_str!("../../i18n/playbook-source.ftl").lines().find_map(|line| {
        let (key, value) = line.split_once(" = ")?;
        (key == id).then_some(value)
    })
}

/// Use app copy only for recognised package wording. A reworded or unknown
/// option keeps its own text, in English as well as translated languages.
fn guarded(id: &str, package_text: &str) -> String {
    let catalog = super::current();
    let trimmed = package_text.trim();
    match playbook_source(id) {
        Some(source) if source.trim() == trimmed => catalog.format(id, None, &[]),
        _ => trimmed.to_owned(),
    }
}

/// The label for an option, translated when this app knows it.
pub fn option_label(name: &str, package_text: &str) -> String {
    guarded(&format!("playbook-option-{name}"), package_text)
}

/// Explanations must follow the same compatibility guard as their labels.
pub fn known_option_consequence(name: &str, package_text: &str) -> Option<String> {
    (playbook_source(&format!("playbook-option-{name}")) == Some(package_text.trim()))
        .then(|| option_consequence(name))
        .flatten()
}

/// The one line playbook.conf repeats on every checkbox page. Only this
/// exact text is hidden; a package that says anything else, however it
/// starts, shows its own words.
const PAGE_BOILERPLATE: &[&str] =
    &["Select the options you would like to use, they can be changed in the Atlas folder later."];

pub fn is_page_boilerplate(text: &str) -> bool {
    PAGE_BOILERPLATE.contains(&text.trim())
}

/// The playbook's own description of a page, translated when this app knows
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
            Notice::SettingsNotSaved { error } => error.clone(),
            Notice::SessionUnreadable { error, record } => {
                t!("notice-session-unreadable-message", path = record.display().to_string(), error = error)
            }
        }
    }
}

impl AcquireProblem {
    pub fn text(&self) -> String {
        match self {
            AcquireProblem::NoPlaybookAsset { version } => t!("acquire-no-asset", version = version),
            AcquireProblem::Unsupported { version } => t!("acquire-unsupported", version = version),
            AcquireProblem::Other { error } => t!("acquire-failed", error = error),
        }
    }
}

impl Preflight {
    pub fn text(&self, system: &SystemInfo) -> String {
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
            Preflight::RecordUnreadable { error } => t!("preflight-record-unreadable", error = error),
            Preflight::Refused { error } => t!("preflight-refused", error = error),
        }
    }
}

impl ElevationProblem {
    pub fn text(&self) -> String {
        match self {
            ElevationProblem::Declined => t!("elevation-declined"),
            ElevationProblem::DeclinedContinue => t!("elevation-declined-continue"),
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
    fn security_summaries_read_as_before() {
        english(|| {
            assert_eq!(security_summary(&SwitchCounts { off: 2, on: 0, unknown: 2 }), "2 can't be read");
            assert_eq!(
                security_summary(&SwitchCounts { off: 2, on: 1, unknown: 1 }),
                "1 still on, 1 can't be read"
            );
            assert_eq!(security_summary(&SwitchCounts { off: 4, on: 0, unknown: 0 }), "All off");
        });
    }

    #[test]
    fn check_details_keep_raw_diagnostics_and_identifiers_verbatim() {
        english(|| {
            let missing = CheckDetail::BuildUnsupported { supported: vec![], actual: 26200 };
            assert_eq!(
                missing.text(&SystemInfo::default()),
                "This playbook does not declare any supported Windows builds. Choose a full playbook build instead of a LocalTest package."
            );
            let system = SystemInfo {
                product_name: "Windows 11 Pro".into(),
                display_version: "25H2".into(),
                build: 26200,
                revision: 1234,
                ..Default::default()
            };
            assert_eq!(system_description(&system), "Windows 11 Pro 25H2 (build 26200.1234)");
            let unsupported = CheckDetail::BuildUnsupported { supported: vec![26100, 26200], actual: 22631 };
            assert_eq!(
                unsupported.text(&system),
                "This Atlas version requires Windows build 26100 or 26200. Your PC has build 22631. Install a supported Windows version before continuing."
            );
            let one = CheckDetail::UpdatesPending { titles: vec!["KB1".into()] };
            assert_eq!(one.text(&system), "Install this update first: KB1.");
            let three =
                CheckDetail::UpdatesPending { titles: vec!["KB1".into(), "KB2".into(), "KB3".into()] };
            assert_eq!(three.text(&system), "Install 3 updates first, including KB1; KB2.");
            let raw = CheckDetail::UpdatesUnknown { error: "0x80240438: la conexión falló".into() };
            assert!(raw.text(&system).ends_with("(0x80240438: la conexión falló)"));
            let av = CheckDetail::AntivirusFound { products: vec!["Avast".into(), "Norton".into()] };
            assert_eq!(
                av.text(&system),
                "Antivirus software may block installation: Avast, Norton. Uninstall this software before continuing."
            );
        });
    }

    #[test]
    fn outcomes_and_phases_map_to_advice() {
        english(|| {
            let applying = InstallOutcome::Failed(1).advice(Phase::Applying);
            assert!(applying.contains("Some changes may already have been made"));
            assert!(applying.contains("turn the protections you turned off back on"));
            assert!(applying.contains("if they're still available"));
            assert!(!InstallOutcome::Failed(1).advice(Phase::Applying).contains("Nothing"));
            assert!(InstallOutcome::Failed(1).advice(Phase::Preflight).contains("before changing anything"));
            assert!(InstallOutcome::Failed(2).advice(Phase::Applying).contains("requirements"));
            assert_eq!(InstallOutcome::Lost.title(), "Couldn't confirm the installation result");
        });
    }

    #[test]
    fn playbook_text_is_translated_only_when_it_matches_the_source() {
        english(|| {
            assert_eq!(option_label("defender-disable", "Disable Defender"), "Remove Microsoft Defender");
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
}
