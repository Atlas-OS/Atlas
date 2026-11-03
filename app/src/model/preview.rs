//! The debug-only `ATLAS_PREPARATION_PREVIEW` fixture, which opens the app
//! in a chosen state for review captures: Home with an update on offer, the
//! completion window, or the install flow at Get ready in a preparation or
//! check state, Your choices, Windows Security with a chosen reading, or
//! Install ready to start. Its package is a stand-in, so updating,
//! restarting and installing all do nothing while a preview shows.

use std::sync::Arc;
use std::sync::atomic::Ordering;

use serde_json::json;

use super::{
    AppModel, Origin, Page, PlaybookSource, Preflight, ReleaseCheck, RestartConfirmation, RestartKind,
    RestoreStatus, Step, UpdatePath,
};
use crate::services::atlas_state::{InstallIdentity, InstallMode, Unfinished};
use crate::services::installer::InstallRequest;
use crate::services::legacy_choices::Facts;
use crate::services::preparation::{RestartProblem, Stage, State};
use crate::services::releases::Release;
use crate::services::requirements::{CheckDetail, CheckId, CheckResult, Verdict};
use crate::services::security::{SecurityStatus, Switch};
use crate::services::session::SessionRecord;
use crate::services::system::SystemInfo;
use crate::services::update_access::{
    Blocker, BlockerKind, Carry, CarryToggle, Rebuild, UpdateAccess, parse_journal, parse_last_result,
};
use crate::services::{iso, settings};

const VARIABLE: &str = "ATLAS_PREPARATION_PREVIEW";

/// Whether a debug build is showing a preparation preview, which prepares
/// and restarts nothing.
pub(super) fn active() -> bool {
    cfg!(debug_assertions) && std::env::var_os(VARIABLE).is_some()
}

/// The preparation preview a debug build was asked to show, if any.
pub(super) fn requested() -> Option<String> {
    if cfg!(debug_assertions) { std::env::var(VARIABLE).ok() } else { None }
}

/// Puts a newly built model in the state `preview` names.
pub(super) fn apply(model: &mut AppModel, preview: &str) {
    if let Some(state) = preview.strip_prefix("home-") {
        apply_home(model, state);
        return;
    }
    if preview == "installed-update-off" {
        apply_installed(model);
        return;
    }
    if preview == "installed-choices-not-applied" {
        apply_not_applied(model);
        return;
    }
    let step = match preview {
        _ if preview.starts_with("options-") => Step::Options,
        _ if preview.starts_with("security-") => Step::Security,
        _ if preview.starts_with("install-") => Step::Install,
        _ => Step::Ready,
    };
    let windows = preview.strip_prefix("windows-");
    // The cause the worker names for a failed move to 26H2.
    let outcome = windows.and_then(|state| {
        FEATURE_OUTCOMES.iter().find(|(name, _)| *name == state).map(|(_, reason)| *reason)
    });
    // The preparation state, whether it has a job folder to open, and the
    // worker's last report.
    let (state, has_job, report) = match preview {
        "busy" | "stopping" => {
            (State::Running { stage: Stage::StoreInstall, completed: 4, total: 12 }, true, None)
        }
        "complete" | "checks-warnings" => (State::Ready, true, None),
        "resume" => (State::Ready, false, None),
        "download" => (
            State::Running { stage: Stage::WindowsDownload, completed: 4, total: 5 },
            false,
            Some(json!({
                "schema": 1, "status": "running", "stage": "windows-download", "completed": 4, "total": 5,
                "activity": {
                    "percent": 99, "currentUpdate": "2026-09 Security Update (KB5129195)",
                    "bytesDownloaded": 1592200000u64, "bytesTotal": 1592200000u64
                }
            })),
        ),
        "failed" => (
            State::Failed,
            true,
            Some(json!({
                "schema": 1, "status": "failed", "stage": "store-install", "completed": 0, "total": 1,
                "activity": {
                    "failureMessage": "The package could not be installed because resources it modifies are currently in use.",
                    "errorCode": "0x80073D02", "packageName": "NanaZip"
                }
            })),
        ),
        "failed-battery" => (
            State::Failed,
            true,
            Some(json!({
                "schema": 1, "status": "failed", "stage": "store-install", "completed": 0, "total": 1,
                "activity": {
                    "failureMessage": "Microsoft Store needs attention: Microsoft.WindowsStore_8wekyb3d8bbwe, PausedLowBattery",
                    "reason": "store-paused-battery", "packageName": "WindowsStore"
                }
            })),
        ),
        "unconfirmed" => (State::Failed, true, None),
        "reboot" | "reboot-others" => (State::Reboot, true, None),
        // Atlas reopened after its own restart, and updating stopped by the user.
        "resumed" => (State::Resumed, true, None),
        "cancelled" => (State::Cancelled, true, None),
        "restart-persists" => {
            (State::RestartPersists { reasons: vec!["servicing".into(), "file-renames".into()] }, false, None)
        }
        // Microsoft Store itself, before the apps.
        "store-updating" | "store-repairing" => {
            let stage = if preview == "store-updating" { "store-self-update" } else { "store-repair" };
            let report = json!({
                "schema": 1, "status": "running", "stage": stage, "completed": 0, "total": 0,
                "activity": { "percent": 35 }
            });
            let stage = if preview == "store-updating" { Stage::StoreSelfUpdate } else { Stage::StoreRepair };
            (State::Running { stage, completed: 0, total: 0 }, true, Some(report))
        }
        "store-updated" | "store-bootstrapped" | "store-repaired" | "store-skipped-removed" => (
            State::Ready,
            true,
            Some(json!({
                "schema": 1, "status": "complete", "stage": "verify", "completed": 0, "total": 0,
                "activity": { "storeOutcome": preview }
            })),
        ),
        "store-repair-failed" => (
            State::Failed,
            true,
            Some(json!({
                "schema": 1, "status": "failed", "stage": "store-repair", "completed": 0, "total": 0,
                "activity": {
                    "failureMessage": "Microsoft Store couldn't be repaired: Microsoft Store is not registered for this user. Open Store once, then try again.",
                    "reason": "store-repair-failed"
                }
            })),
        ),
        // Windows' component store: repaired before updates, an update that still
        // failed on it, and damage Windows can't repair.
        "components-repairing" => (
            State::Running { stage: Stage::WindowsRepair, completed: 0, total: 0 },
            true,
            Some(json!({
                "schema": 1, "status": "running", "stage": "windows-repair", "completed": 0, "total": 0,
                "activity": { "elapsedSeconds": 754, "unchangedSeconds": 750 }
            })),
        ),
        "components-damaged" | "components-unrepairable" => {
            let (stage, activity) = if preview == "components-damaged" {
                (
                    "windows-install",
                    json!({
                        "failureMessage": "Windows could not install every update: 4. See updates.log.",
                        "errorCode": "0x80073712"
                    }),
                )
            } else {
                (
                    "windows-search",
                    json!({
                        "failureMessage": "Windows reports that its component store is damaged beyond repair.",
                        "reason": "component-store-unrepairable"
                    }),
                )
            };
            let report = json!({
                "schema": 1, "status": "failed", "stage": stage, "completed": 0, "total": 0, "activity": activity
            });
            (State::Failed, true, Some(report))
        }
        "network" => (State::Network, false, None),
        "network-limited" => (
            State::Network,
            false,
            Some(json!({
                "schema": 1, "status": "network", "stage": "verify", "completed": 0, "total": 0,
                "activity": { "networkReason": "limited" }
            })),
        ),
        "previous-worker" => (State::WaitingExternal, true, None),
        // Moving Windows to 26H2: the restart, its outcomes and the steps around them.
        "windows-running" => (
            State::Running { stage: Stage::WindowsDownload, completed: 0, total: 1 },
            false,
            Some(json!({
                "schema": 1, "status": "running", "stage": "windows-download", "completed": 0, "total": 1,
                "activity": {
                    "percent": 42, "currentUpdate": "Windows 11, version 26H2",
                    "bytesDownloaded": 61000u64, "bytesTotal": 145000u64
                }
            })),
        ),
        // Waiting for Windows Update to offer the new version.
        "windows-waiting" => (
            State::Running { stage: Stage::WindowsSearch, completed: 0, total: 0 },
            false,
            Some(json!({
                "schema": 1, "status": "running", "stage": "windows-search", "completed": 0, "total": 0,
                "activity": { "waiting": "feature-offer", "elapsedSeconds": 245, "unchangedSeconds": 200 }
            })),
        ),
        "windows-restart" | "windows-commit-failed" => {
            (State::Reboot, true, Some(report_reasons(&["feature-update"])))
        }
        "windows-resumed" => (State::Resumed, true, None),
        // Windows reinstalled itself during the move; Atlas puts its changes back.
        "windows-rebuilt" | "options-rebase" | "options-rebase-partial" => (State::Ready, true, None),
        _ if outcome.is_some() => (State::Failed, true, outcome.map(feature_failure)),
        // The steps after Get ready follow a preparation that finished.
        _ if step != Step::Ready => (State::Ready, false, None),
        _ => (State::Idle, false, None),
    };
    model.preparation = state;
    if has_job {
        model.preparation_job = Some(std::env::temp_dir());
    }
    model.preparation_progress = report.and_then(|report| serde_json::from_value(report).ok());
    if preview == "stopping" {
        model.preparation_cancel.store(true, Ordering::Relaxed);
    }
    match preview {
        "resume" => {
            let options = iso::default_options(model.manifest());
            let unfinished =
                Unfinished { held: Some(options), choose_again: false, mode: InstallMode::Fresh };
            model.install_identity = Ok(InstallIdentity::Resume("0.6.0".into(), unfinished));
        }
        "ineligible" => model.install_identity = Ok(InstallIdentity::Installed("0.3.2".into())),
        // Restart now was chosen with two other people signed in.
        "reboot-others" => {
            model.restart_confirmation = Some(RestartConfirmation {
                kind: RestartKind::Preparation,
                people: vec!["Alex".into(), "Sam".into()],
            })
        }
        _ => {}
    }
    model.elevated = true;
    // The checks pass, so the preparation actions show as they do on a supported PC.
    model.checks = CheckId::ALL.iter().map(|&id| (id, Some(passing(id)))).collect();
    if let Some(state) = windows {
        apply_windows(model, state);
    }
    let fail = |id, verdict, detail| (id, Some(CheckResult { id, verdict, detail }));
    let updates = || {
        fail(
            CheckId::PendingUpdates,
            Verdict::Fail,
            CheckDetail::UpdatesPending {
                titles: vec![
                    "2026-09 Cumulative Update for Windows 11 Version 25H2 (KB5129195)".into(),
                    "Windows Malicious Software Removal Tool x64 - v5.135 (KB890830)".into(),
                    "Microsoft Defender Antivirus antimalware platform update (KB4052623)".into(),
                ],
            },
        )
    };
    let replace = |checks: &mut Vec<_>, results: Vec<(CheckId, Option<CheckResult>)>| {
        for (id, result) in results {
            if let Some(slot) = checks.iter_mut().find(|(check, _)| *check == id) {
                *slot = (id, result);
            }
        }
    };
    match preview {
        // Updates and a restart Get ready's update step takes care of.
        "pending-updates" => replace(
            &mut model.checks,
            vec![
                updates(),
                fail(
                    CheckId::PendingReboot,
                    Verdict::Fail,
                    CheckDetail::RebootPending { reasons: vec!["windows-update".into()] },
                ),
            ],
        ),
        // Blockers, a check that couldn't run and advice, with updates waiting.
        "checks-blocked" => replace(
            &mut model.checks,
            vec![
                updates(),
                fail(
                    CheckId::ThirdPartyAntivirus,
                    Verdict::Fail,
                    CheckDetail::AntivirusFound { products: vec!["Avast Free Antivirus".into()] },
                ),
                fail(CheckId::Power, Verdict::Unknown, CheckDetail::PowerUnknown),
                fail(CheckId::Activation, Verdict::Warn, CheckDetail::ActivationMissing),
            ],
        ),
        "checks-warnings" => replace(
            &mut model.checks,
            vec![
                // Only a note: no restart flag is set.
                fail(
                    CheckId::PendingReboot,
                    Verdict::Pass,
                    CheckDetail::RebootFileRenames {
                        files: vec![
                            r"\??\C:\Program Files\WindowsApps\Microsoft.GamingServices\x64\gs.sys".into(),
                        ],
                    },
                ),
                fail(CheckId::Activation, Verdict::Warn, CheckDetail::ActivationMissing),
            ],
        ),
        _ => {}
    }
    // An unpacked package, except where the preview is about not having one.
    if !matches!(preview, "idle" | "ineligible") {
        let manifest = model.builtin_manifest.clone();
        model.playbook = Some(PlaybookSource {
            dir: std::env::temp_dir(),
            manifest,
            origin: Origin::Unpacked,
            archive: None,
        });
    }
    if let Some(state) = preview.strip_prefix("options-") {
        apply_rebase(model, state);
    }
    if let Some(state) = preview.strip_prefix("security-defender-") {
        apply_defender(model, state);
    }
    if preview == "security-absent" {
        // Defender gone without Atlas's package, as the user chose to remove it.
        model.options.remove("defender-enable");
        model.options.insert("defender-disable".into());
    }
    if preview == "install-choose-again" {
        apply_contradicted(model, UpdatePath::ChooseAgain);
    }
    if let Some(reading) = security_reading(preview) {
        model.env.adapters.read_security = Arc::new(move || reading);
        // Nothing reads Windows Security until the flow moves, so the step
        // opens on the stand-in reading, which stays fresh until then.
        model.security = reading;
        model.security_read_at =
            Some(std::time::Instant::now() + std::time::Duration::from_secs(24 * 60 * 60));
    }
    if preview == "install-refused" {
        model.preflight_problem = Some(Preflight::Refused {
            error: "the installer's log could not be created: Access is denied. (os error 5)".into(),
        });
    }
    if preview == "install-busy" {
        model.preflight_problem = Some(Preflight::Busy);
    }
    model.flow.resume(step).ok();
    model.flow_id = Some(settings::new_flow_id());
    model.page = Page::Install;
}

/// The outcomes of moving Windows a preview can show, by preview name and the
/// cause the worker names.
const FEATURE_OUTCOMES: &[(&str, &str)] = &[
    ("not-offered", "feature-not-offered"),
    ("not-offered-25h2", "feature-not-offered"),
    ("not-offered-ended", "feature-not-offered"),
    ("hardware", "feature-hardware"),
    ("rolled-back", "feature-rolled-back"),
    ("disk-space", "feature-disk-space"),
    ("blocked", "feature-blocked"),
    ("components-lost", "feature-components-lost"),
    ("managed", "feature-managed"),
    ("failed", "feature-failed"),
];

fn report_reasons(reasons: &[&str]) -> serde_json::Value {
    json!({
        "schema": 1, "status": "reboot", "stage": "windows-install", "completed": 0, "total": 0,
        "activity": { "restartReasons": reasons }
    })
}

fn feature_failure(reason: &str) -> serde_json::Value {
    json!({
        "schema": 1, "status": "failed", "stage": "windows-search", "completed": 0, "total": 0,
        "activity": {
            "failureMessage": "Windows Update does not offer KB5121794 to this PC yet.",
            "reason": reason, "errorCode": if reason == "feature-rolled-back" { Some("0x8024200B") } else { None },
            "hardware": "tpm,uefi", "drive": "C:", "freeGb": "3", "neededGb": "6", "setting": "BITS"
        }
    })
}

/// A Windows 11 PC on `build` (`release`), Pro unless `edition` says otherwise.
fn windows_pc(build: u32, release: &str, edition: &str) -> SystemInfo {
    SystemInfo {
        product_name: if edition.starts_with("Core") {
            "Windows 11 Home".into()
        } else {
            "Windows 11 Pro".into()
        },
        display_version: release.into(),
        build,
        revision: 9550,
        edition_id: edition.into(),
        installation_type: "Client".into(),
        build_lab: format!("{build}.9550.amd64fre.ge_release.260918-1415"),
    }
}

/// Atlas's record of a move to 26H2 from 24H2, at `phase`.
fn record(kind: &str, phase: &str) -> UpdateAccess {
    let mut journal = json!({
        "schema": 1, "kind": kind, "phase": phase,
        "source": { "build": 26100, "ubr": 9550, "displayVersion": "24H2", "editionId": "Professional" },
        "createdAt": "2026-10-01T15:41:43Z",
        "items": [ { "id": "service.wuauserv", "lifted": true }, { "id": "pause.PausedFeatureStatus", "lifted": true } ],
        "history": [ { "at": "2026-10-01T15:42:10Z", "event": "targeted", "detail": "26H2" } ]
    });
    if kind == "transition" {
        journal["target"] = json!({ "release": "26H2", "build": 26300, "kb": "5121794" });
    }
    UpdateAccess { journal: parse_journal(&journal.to_string()).ok(), ..UpdateAccess::default() }
}

/// The record of a move during which Windows reinstalled itself, keeping an
/// Atlas 0.5.0 install whose choices showed `options`, with the record its
/// launcher left for keeping Windows' default processor protections.
fn record_rebuilt(options: &[&str]) -> UpdateAccess {
    let mut access = record("transition", "on-target");
    if let Some(journal) = access.journal.as_mut() {
        journal.rebuild = Some(Rebuild {
            rebuilt: true,
            signals: ["windows-old", "setup-log", "packages-missing", "atlas-files-missing"]
                .map(str::to_owned)
                .to_vec(),
        });
        let launcher = CarryToggle {
            name: "Mitigations".into(),
            state: 1,
            path: Some("Set Windows Default Mitigations.cmd".into()),
        };
        journal.carry = Some(Carry {
            atlas_version: Some("0.5.0".into()),
            options: options.iter().map(|option| (*option).to_owned()).collect(),
            option_source: "observed".into(),
            edge: false,
            toggles: options.contains(&"mitigations-default").then_some(launcher).into_iter().collect(),
        });
    }
    access
}

/// On 26H2 after Windows reinstalled itself: every check passes.
fn on_rebuilt_windows(model: &mut AppModel) {
    model.system = windows_pc(26300, "26H2", "Professional");
    if let Some(slot) = model.checks.iter_mut().find(|(check, _)| *check == CheckId::SupportedBuild) {
        *slot = (CheckId::SupportedBuild, Some(passing(CheckId::SupportedBuild)));
    }
    model.install_identity = Ok(InstallIdentity::Installed("0.5.0".into()));
}

/// Your choices after Windows reinstalled itself: every choice kept, or the
/// mitigations choice missing. Or an update or reinstall of the installed
/// Atlas (see [`apply_update`]).
fn apply_rebase(model: &mut AppModel, state: &str) {
    on_rebuilt_windows(model);
    if apply_update(model, state) {
        return;
    }
    let mut options =
        vec!["defender-disable", "auto-updates-disable", "disable-hibernation", "uninstall-edge"];
    if state != "rebase-partial" {
        options.push("mitigations-default");
    }
    model.update_access = Some(record_rebuilt(&options));
    model.apply_recorded_choices();
}

const NO_DEFENDER: &str = "Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0";
const NO_TELEMETRY: &str = "Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0";

/// Toggle records, by name.
fn records(records: &[(&str, u32)]) -> std::collections::HashMap<String, u32> {
    records.iter().map(|(name, state)| ((*name).to_owned(), *state)).collect()
}

/// Your choices on an update or reinstall, for the `options-` previews it
/// names; whether `state` was one of them. From Atlas 0.5.0: the first
/// screen, whose list can't tell the keyboard choice (`update-path`), or
/// keeping the choices where only the old Toolbox recorded processor
/// protections, so that screen is asked (`keep-partial`). Reinstalling over
/// a record the PC contradicts, choosing again: the first screen with the
/// line that says so (`choose-again`), the Defender and processor
/// protections screens with what each answer changes
/// (`choose-again-defender`, `choose-again-mitigations`), and the extras with
/// what an update can't undo, another browser beside the one installed and
/// cleared boxes that turn Windows features back on (`choose-again-fixed`).
fn apply_update(model: &mut AppModel, state: &str) -> bool {
    match state {
        "update-path" => {
            model.atlas = Ok(None);
            model.update_access = Some(UpdateAccess::default());
            model.pc_facts = Facts {
                packages: vec![NO_TELEMETRY.into()],
                toggles: records(&[
                    ("Mitigations", 1),
                    ("AutomaticUpdates", 0),
                    ("Hibernation", 0),
                    ("PowerSaving", 0),
                ]),
                launchers: [("Mitigations".to_owned(), "Set Windows Default Mitigations.cmd".to_owned())]
                    .into(),
                browser: Some("Brave".into()),
                edge: Some(false),
                appx: vec!["Microsoft.WindowsCalculator_8wekyb3d8bbwe".into()],
                toolbox: Some(true),
                toolbox_program: Some(true),
                core_isolation_off: Some(true),
                browsers: Some(vec!["browser-brave".into()]),
                ..Facts::default()
            };
            model.apply_recorded_choices();
        }
        "keep-partial" => {
            model.atlas = Ok(None);
            model.update_access = Some(UpdateAccess::default());
            // The old Toolbox's own record, without a launcher's name beside it.
            model.pc_facts = Facts {
                packages: vec![NO_TELEMETRY.into()],
                toggles: records(&[("Mitigations", 2), ("AutomaticUpdates", 0)]),
                edge: Some(true),
                language_hotkey: Some("1".into()),
                ..Facts::default()
            };
            model.apply_recorded_choices();
            model.option_screen = 1;
        }
        "choose-again" => apply_contradicted(model, UpdatePath::ChooseAgain),
        "choose-again-defender" | "choose-again-mitigations" => {
            apply_contradicted(model, UpdatePath::ChooseAgain);
            model.option_screen = if state == "choose-again-defender" { 1 } else { 2 };
        }
        "choose-again-fixed" => {
            apply_contradicted(model, UpdatePath::ChooseAgain);
            model.pc_facts.browser = Some("Brave".into());
            model.pc_facts.browsers = Some(vec!["browser-brave".into()]);
            model.recorded_choices_applied = false;
            model.apply_recorded_choices();
            for (name, ticked) in [
                ("browser-brave", false),
                ("browser-firefox", true),
                ("remove-snipping-tool", true),
                ("disable-power-saving", false),
                ("disable-core-isolation", false),
            ] {
                if ticked {
                    model.options.insert(name.into());
                } else {
                    model.options.remove(name);
                }
            }
            model.option_screen = model.option_screens().len().saturating_sub(1);
        }
        _ => return false,
    }
    true
}

/// A reinstall of Atlas 0.6.0 over a record this PC contradicts, as an
/// earlier release candidate left it: Defender kept while Atlas's NoDefender
/// package still removes it, Windows Update and processor protections
/// recorded off while their toggles turned them back on, every protection
/// on, and VBS off without its option. `path` is how this flow treats it.
fn apply_contradicted(model: &mut AppModel, path: UpdatePath) {
    model.system = windows_pc(26300, "26H2", "Professional");
    model.install_identity = Ok(InstallIdentity::Installed("0.6.0".into()));
    model.atlas = serde_json::from_value(json!({
        "schemaVersion": 1, "installedVersion": "0.6.0", "installedAt": "2026-10-27T18:00:00+00:00",
        "mode": "Reapply", "options": [
            "auto-updates-disable", "defender-enable", "disable-power-saving", "install-toolbox",
            "keyboard-single", "mitigations-disable", "uninstall-edge"
        ]
    }))
    .map(Some)
    .map_err(|error| error.to_string());
    model.update_access = Some(UpdateAccess::default());
    model.pc_facts = Facts {
        packages: vec![NO_DEFENDER.into(), NO_TELEMETRY.into()],
        toggles: records(&[("AutomaticUpdates", 1), ("Mitigations", 2), ("PowerSaving", 0), ("VbsState", 0)]),
        edge: Some(false),
        appx: vec![
            "Microsoft.ScreenSketch_8wekyb3d8bbwe".into(),
            "Microsoft.WindowsCalculator_8wekyb3d8bbwe".into(),
        ],
        toolbox: Some(true),
        toolbox_program: Some(true),
        core_isolation_off: Some(true),
        browsers: Some(Vec::new()),
        defender: Some(false),
        ..Facts::default()
    };
    model.update_path = path;
    model.recorded_choices_applied = false;
    model.apply_recorded_choices();
}

/// Windows Security with Microsoft Defender gone, for the `security-defender-`
/// previews: Atlas's package removed it and choosing again brings it back
/// (`restore`), or keeping the choices leaves it removed (`removed`); or no
/// Atlas package removed it, but the record keeps it (`missing`).
fn apply_defender(model: &mut AppModel, state: &str) {
    match state {
        "restore" | "removed" => {
            let path = if state == "restore" { UpdatePath::ChooseAgain } else { UpdatePath::Keep };
            apply_contradicted(model, path);
            if state == "restore" {
                model.options.remove("defender-disable");
                model.options.insert("defender-enable".into());
            }
        }
        _ => {
            model.system = windows_pc(26300, "26H2", "Professional");
            model.install_identity = Ok(InstallIdentity::Installed("0.6.0".into()));
            model.atlas = serde_json::from_value(json!({
                "schemaVersion": 1, "installedVersion": "0.6.0", "installedAt": "2026-10-27T18:00:00+00:00",
                "mode": "Upgrade", "options": ["defender-enable", "mitigations-default", "auto-updates-disable", "keyboard-shortcuts"]
            }))
            .map(Some)
            .map_err(|error| error.to_string());
            model.update_access = Some(UpdateAccess::default());
            model.pc_facts =
                Facts { packages: vec![NO_TELEMETRY.into()], defender: Some(false), ..Facts::default() };
            model.apply_recorded_choices();
        }
    }
}

/// Windows Update off and paused by the user's own Atlas choices.
fn blockers() -> Vec<Blocker> {
    vec![Blocker { kind: BlockerKind::Off, owned: true }, Blocker { kind: BlockerKind::Paused, owned: true }]
}

/// Get ready on a PC Atlas moves to 26H2.
fn apply_windows(model: &mut AppModel, state: &str) {
    let optional = matches!(state, "choice" | "keep" | "not-offered-25h2");
    model.system = if optional {
        windows_pc(26200, "25H2", "Professional")
    } else {
        windows_pc(26100, "24H2", "Professional")
    };
    if !optional {
        let id = CheckId::SupportedBuild;
        let detail = CheckDetail::BuildTransition { current: "24H2".into(), release: "26H2".into() };
        if let Some(slot) = model.checks.iter_mut().find(|(check, _)| *check == id) {
            *slot = (id, Some(CheckResult { id, verdict: Verdict::Fail, detail }));
        }
    }
    model.windows_terms_accepted = !matches!(state, "required" | "choice" | "blockers");
    model.windows_transition_declined = state == "keep";
    model.update_access = Some(match state {
        "required" | "ready" | "choice" | "keep" => UpdateAccess::default(),
        "blockers" => UpdateAccess { blockers: blockers(), ..UpdateAccess::default() },
        "restart" | "commit-failed" => record("transition", "installed"),
        "rebuilt" => {
            on_rebuilt_windows(model);
            record_rebuilt(&[
                "defender-disable",
                "mitigations-default",
                "auto-updates-disable",
                "uninstall-edge",
            ])
        }
        "resumed" => {
            model.system = windows_pc(26300, "26H2", "Professional");
            if let Some(slot) = model.checks.iter_mut().find(|(check, _)| *check == CheckId::SupportedBuild) {
                *slot = (CheckId::SupportedBuild, Some(passing(CheckId::SupportedBuild)));
            }
            record("transition", "installed")
        }
        _ => record("transition", "targeted"),
    });
    if state == "commit-failed" {
        model.preparation_problem = Some(RestartProblem::Commit);
    }
    // Not offered yet: Atlas looks again by itself, or stopped after 2 hours
    // and put the settings back.
    if matches!(state, "not-offered" | "not-offered-25h2") {
        // 34 minutes in, the next look 6 minutes away.
        let now = std::time::Instant::now();
        model.offer_wait = Some(super::offer_wait::OfferWait {
            next_check: Some(now + std::time::Duration::from_secs(6 * 60 - 1)),
            ..super::offer_wait::OfferWait::started(now)
        });
        model.offer_waiting_since = now.checked_sub(std::time::Duration::from_secs(34 * 60));
    }
    if state == "not-offered-ended" {
        model.offer_wait = Some(super::offer_wait::OfferWait {
            expired: true,
            ..super::offer_wait::OfferWait::started(std::time::Instant::now())
        });
        model.update_access = Some(UpdateAccess::default());
    }
}

/// Home on a PC with Atlas 0.5.0 and Atlas 0.6.0 on offer.
fn apply_home(model: &mut AppModel, state: &str) {
    model.system = match state {
        "24h2-home" => windows_pc(26100, "24H2", "Core"),
        "23h2" => windows_pc(22631, "23H2", "Professional"),
        "25h2" => windows_pc(26200, "25H2", "Professional"),
        "update-access-after" => windows_pc(26300, "26H2", "Professional"),
        _ => windows_pc(26100, "24H2", "Professional"),
    };
    model.install_identity = Ok(InstallIdentity::Installed("0.5.0".into()));
    model.release = ReleaseCheck::Ready {
        release: Release {
            tag_name: "0.6.0".into(),
            body: "## Atlas 0.6.0\n\nAtlas Manager installs and updates Atlas.".into(),
            html_url: String::new(),
            published_at: "2026-10-14T12:00:00Z".into(),
            assets: vec![],
        },
    };
    model.update_access = Some(match state {
        "update-access" | "put-back-failed" => record("transition", "targeted"),
        "update-access-after" => record("transition", "on-target"),
        "not-offered" => {
            let mut access = record("transition", "targeted");
            if let Some(journal) = access.journal.as_mut() {
                journal.history.push(crate::services::update_access::HistoryEntry {
                    at: "2026-10-02T09:00:00Z".into(),
                    event: "outcome".into(),
                    detail:
                        "reason=feature-not-offered code= Windows Update does not offer 26H2 to this PC yet."
                            .into(),
                });
            }
            access
        }
        "update-access-unreadable" => UpdateAccess {
            journal_error: Some(
                "the Windows Update record has schema 2, which this version doesn't read".into(),
            ),
            ..UpdateAccess::default()
        },
        _ => UpdateAccess::default(),
    });
    if state == "restart-others" {
        // Restart now, for the restart an install still owes, with one other person signed in.
        model.owed_restart = Some(Default::default());
        model.restart_confirmation =
            Some(RestartConfirmation { kind: RestartKind::Owed, people: vec!["Alex".into()] });
    }
    if state == "put-back-failed" {
        model.restore_status =
            RestoreStatus::Failed("feature-install-active: An Atlas install is unfinished; its closing step puts the settings back.".into());
    }
    if let Some(defender) = state.strip_prefix("defender-") {
        // Atlas 0.6.0, recorded as keeping Microsoft Defender, which is gone:
        // Atlas's package still removes it (`not-restored`), or nothing Atlas
        // did removed it (`missing`).
        model.install_identity = Ok(InstallIdentity::Installed("0.6.0".into()));
        model.atlas = serde_json::from_value(json!({
            "schemaVersion": 1, "installedVersion": "0.6.0", "installedAt": "2026-10-27T18:00:00+00:00",
            "mode": "Upgrade", "options": ["defender-enable", "mitigations-default", "auto-updates-disable", "keyboard-shortcuts"]
        }))
        .map(Some)
        .map_err(|error| error.to_string());
        let mut packages = vec![NO_TELEMETRY.to_owned()];
        if defender == "not-restored" {
            packages.insert(0, NO_DEFENDER.into());
        }
        model.pc_facts = Facts { packages, defender: Some(false), ..Facts::default() };
        model.protection = Some(SecurityStatus {
            tamper_protection: Switch::Unknown,
            real_time_protection: Switch::Unknown,
            cloud_delivered: Switch::Unknown,
            sample_submission: Switch::Unknown,
            defender_present: false,
        });
    }
    model.elevated = true;
    model.page = Page::Home;
}

/// The "Atlas is installed" window after an update whose last step turned
/// Windows Update off again, as the user had chosen.
fn apply_installed(model: &mut AppModel) {
    model.system = windows_pc(26300, "26H2", "Professional");
    model.atlas = serde_json::from_value(json!({
        "schemaVersion": 1, "installedVersion": "0.6.0", "installedAt": "2026-10-14T12:30:00+00:00",
        "mode": "Upgrade", "options": ["defender-enable", "mitigations-default", "auto-updates-disable"]
    }))
    .map(Some)
    .map_err(|error| error.to_string());
    let last = parse_last_result(
        &json!({
            "schema": 1, "closedAt": "2026-10-14T12:20:00Z", "outcome": "Installed", "kind": "transition",
            "restored": ["policy.DeferQualityUpdates"], "owned": ["service.wuauserv", "policy.DisableWindowsUpdateAccess"],
            "build": 26300, "ubr": 9550
        })
        .to_string(),
    )
    .ok();
    model.update_access = Some(UpdateAccess { last_result: last, ..UpdateAccess::default() });
    model.page = Page::Installed;
}

/// The "Atlas is installed" window after choosing again asked to turn VBS
/// off, which a policy on the PC kept on, so the install recorded it on and
/// that it couldn't apply the choice. As after the install's restart,
/// startup has closed the install out and kept what it asked for; its log
/// says why.
fn apply_not_applied(model: &mut AppModel) {
    model.system = windows_pc(26300, "26H2", "Professional");
    let requested = ["defender-enable", "mitigations-default", "auto-updates-disable", "keyboard-shortcuts"];
    model.atlas = serde_json::from_value(json!({
        "schemaVersion": 1, "installedVersion": "0.6.0", "installedAt": "2026-10-31T12:30:00+00:00",
        "mode": "Reapply", "options": requested,
        "history": [{
            "version": "0.6.0", "mode": "Reapply", "completedAt": "2026-10-31T12:30:00+00:00",
            "notApplied": ["disable-core-isolation"]
        }]
    }))
    .map(Some)
    .map_err(|error| error.to_string());
    model.install_identity = Ok(InstallIdentity::Installed("0.6.0".into()));
    model.pc_facts = Facts { packages: vec![NO_TELEMETRY.into()], ..Facts::default() };
    let mut options: Vec<String> = requested.iter().map(|option| (*option).to_owned()).collect();
    options.push("disable-core-isolation".into());
    let log = std::env::temp_dir().join("install-preview.log");
    model.finished_session = Some(SessionRecord {
        id: "preview".into(),
        pid: 0,
        process_start: 0,
        started_at: "2026-10-31T12:00:00Z".into(),
        exit_path: log.with_extension("exit"),
        log_path: log,
        request: InstallRequest {
            playbook_dir: std::env::temp_dir(),
            options,
            restart: true,
            windows_security_confirmed: false,
            choose_again: true,
        },
    });
    model.update_access = Some(UpdateAccess::default());
    model.page = Page::Installed;
}

/// The Windows Security reading a security or install preview shows.
fn security_reading(preview: &str) -> Option<SecurityStatus> {
    let all = |switch| SecurityStatus {
        tamper_protection: switch,
        real_time_protection: switch,
        cloud_delivered: switch,
        sample_submission: switch,
        defender_present: true,
    };
    Some(match preview {
        "security-on" => SecurityStatus { tamper_protection: Switch::Off, ..all(Switch::On) },
        "security-readable-off" => SecurityStatus { sample_submission: Switch::Unknown, ..all(Switch::Off) },
        "security-unreadable" => all(Switch::Unknown),
        "security-absent"
        | "security-defender-restore"
        | "security-defender-removed"
        | "security-defender-missing" => SecurityStatus { defender_present: false, ..all(Switch::Unknown) },
        "security-off" | "install-ready" | "install-refused" | "install-busy" | "install-choose-again" => {
            all(Switch::Off)
        }
        _ => return None,
    })
}

/// A passing result for check `id`.
pub(super) fn passing(id: CheckId) -> CheckResult {
    let detail = match id {
        CheckId::Administrator => CheckDetail::AdministratorOk,
        CheckId::UserAccount => CheckDetail::UserAccountOk,
        CheckId::SupportedBuild => CheckDetail::BuildSupported,
        CheckId::PendingUpdates => CheckDetail::UpdatesNone,
        CheckId::PendingReboot => CheckDetail::RebootNone,
        CheckId::ThirdPartyAntivirus => CheckDetail::AntivirusNone,
        CheckId::Internet => CheckDetail::InternetOk,
        CheckId::Power => CheckDetail::PowerMains,
        CheckId::Activation => CheckDetail::ActivationOk,
    };
    CheckResult { id, verdict: Verdict::Pass, detail }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::i18n::describe::DefenderAbsence;
    use crate::model::ScreenKind;
    use crate::model::test_harness::{fixture, new_model, run_model_test};

    /// Each review fixture of an update or reinstall opens on the state its
    /// name says, so a capture shows what it is listed for.
    #[test]
    fn the_update_fixtures_open_on_the_state_they_are_named_for() {
        run_model_test(|mut cx| async move {
            let (_temp, _, env) = fixture("preview-update");
            let mut shown = |preview: &str, check: &dyn Fn(&AppModel)| {
                let model = new_model(&mut cx, env.clone());
                model.update(&mut cx, |m, _| {
                    apply(m, preview);
                    check(m);
                });
            };
            let screen = |m: &AppModel| m.option_screens()[m.current_option_screen()].kind;
            shown("options-update-path", &|m| {
                assert_eq!((screen(m), m.update_path), (ScreenKind::UpdatePath, UpdatePath::Keep));
                let update = m.update_choices().unwrap();
                assert!(!update.reinstall && update.missing == [ScreenKind::Keyboard], "{update:?}");
            });
            shown("options-keep-partial", &|m| {
                let kinds: Vec<ScreenKind> = m.option_screens().iter().map(|screen| screen.kind).collect();
                assert_eq!(kinds, [ScreenKind::UpdatePath, ScreenKind::Mitigations]);
                assert_eq!(screen(m), ScreenKind::Mitigations);
            });
            shown("options-choose-again", &|m| {
                assert_eq!(screen(m), ScreenKind::UpdatePath);
                assert!(m.choosing_again());
                let update = m.update_choices().unwrap();
                assert!(update.reinstall);
                assert_eq!(
                    update.differs,
                    [ScreenKind::Defender, ScreenKind::Mitigations, ScreenKind::Updates, ScreenKind::Power]
                );
            });
            shown("options-choose-again-defender", &|m| {
                assert_eq!(screen(m), ScreenKind::Defender);
                assert!(m.options.contains("defender-disable"), "as the PC has it");
            });
            shown("options-choose-again-mitigations", &|m| {
                assert_eq!(screen(m), ScreenKind::Mitigations);
                assert_eq!(m.choice_facts().toggles.get("Mitigations"), Some(&2), "every protection on");
            });
            shown("options-choose-again-fixed", &|m| {
                assert_eq!(screen(m), ScreenKind::Extras);
                for name in ["uninstall-edge", "install-toolbox", "install-another-browser"] {
                    assert!(m.fixed_option(name).is_some(), "{name}");
                }
                for (name, ticked) in [
                    ("browser-firefox", true),
                    ("remove-snipping-tool", true),
                    ("disable-power-saving", false),
                ] {
                    assert_eq!(m.effective_options().iter().any(|o| o == name), ticked, "{name}");
                }
            });
            for (preview, absence) in [
                ("security-defender-restore", DefenderAbsence::Restore),
                ("security-defender-removed", DefenderAbsence::Removed),
                ("security-defender-missing", DefenderAbsence::Missing),
                ("security-absent", DefenderAbsence::Absent),
            ] {
                shown(preview, &|m| {
                    assert_eq!(m.flow.step, Step::Security);
                    assert_eq!(m.defender_absence(), absence, "{preview}");
                });
            }
            shown("install-choose-again", &|m| {
                assert_eq!(m.flow.step, Step::Install);
                assert!(m.install_request().unwrap().choose_again);
            });
            shown("home-defender-not-restored", &|m| {
                assert!(m.page == Page::Home && m.defender_not_restored_shown());
            });
            shown("home-defender-missing", &|m| {
                assert!(m.protection_reminder().is_some_and(|reminder| reminder.missing));
                assert!(!m.defender_not_restored_shown());
            });
            shown("installed-choices-not-applied", &|m| {
                assert_eq!(m.page, Page::Installed);
                assert!(m.session.is_none(), "closed out, as after the restart");
                assert_eq!(m.choices_not_applied(), Some(&["disable-core-isolation".to_owned()][..]));
                assert!(!m.installed().unwrap().options.iter().any(|o| o == "disable-core-isolation"));
            });
        });
    }
}
