//! The debug-only `ATLAS_PREPARATION_PREVIEW` fixture, which opens the
//! install flow in a chosen state for review captures: Get ready in a
//! preparation or check state, Windows Security with a chosen reading, or
//! Install ready to start. Its package is a stand-in, so updating,
//! restarting and installing all do nothing while a preview shows.

use std::sync::Arc;
use std::sync::atomic::Ordering;

use serde_json::json;

use super::{AppModel, Origin, Page, PlaybookSource, Preflight, Step};
use crate::services::atlas_state::InstallIdentity;
use crate::services::preparation::{Stage, State};
use crate::services::requirements::{CheckDetail, CheckId, CheckResult, Verdict};
use crate::services::security::{SecurityStatus, Switch};
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
        "reboot" => (State::Reboot, true, None),
        // Atlas reopened after its own restart, and updating stopped by the user.
        "resumed" => (State::Resumed, true, None),
        "cancelled" => (State::Cancelled, true, None),
        "restart-persists" => {
            (State::RestartPersists { reasons: vec!["servicing".into(), "file-renames".into()] }, false, None)
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
        // The steps after Get ready follow a preparation that finished.
        _ if preview.starts_with("security-") || preview.starts_with("install-") => {
            (State::Ready, false, None)
        }
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
            model.install_identity = Ok(InstallIdentity::Resume("0.6.0".into(), Some(options)));
        }
        "ineligible" => model.install_identity = Ok(InstallIdentity::Installed("0.3.2".into())),
        _ => {}
    }
    model.elevated = true;
    // The checks pass, so the preparation actions show as they do on a supported PC.
    model.checks = CheckId::ALL.iter().map(|&id| (id, Some(passing(id)))).collect();
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
                fail(
                    CheckId::PendingReboot,
                    Verdict::Warn,
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
    let step = match preview {
        _ if preview.starts_with("security-") => Step::Security,
        _ if preview.starts_with("install-") => Step::Install,
        _ => Step::Ready,
    };
    if let Some(reading) = security_reading(preview) {
        model.env.adapters.read_security = Arc::new(move || reading);
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
        "security-absent" => SecurityStatus { defender_present: false, ..all(Switch::Unknown) },
        "security-off" | "install-ready" | "install-refused" | "install-busy" => all(Switch::Off),
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
