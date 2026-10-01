//! A Windows installation USB writer, never a raw ISO-to-disk copy.
use std::fs;
use std::io::{BufRead, Write};
use std::path::Path;
use std::process::Child;
use std::sync::Arc;
use std::sync::atomic::AtomicBool;

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

use super::powershell;

// The drive sizes the worker accepts (Test-AtlasUsbDisk in Write-Usb.ps1).
pub const MIN_BYTES: u64 = 8 << 30;
pub const MAX_BYTES: u64 = 2 << 40;

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct Drive {
    pub number: u32,
    pub name: String,
    pub serial: String,
    pub unique_id: String,
    pub path: String,
    pub size: u64,
    pub volumes: String,
}

#[derive(Clone, Debug, Default, Deserialize)]
pub struct Progress {
    pub stage: String,
    pub done: u64,
    pub total: u64,
}
impl Progress {
    pub fn fraction(&self) -> Option<f32> {
        (self.total > 0).then(|| (self.done as f64 / self.total as f64).clamp(0., 1.) as f32)
    }
}

#[derive(Default, Deserialize)]
pub struct Outcome {
    #[serde(default)]
    pub drives: Vec<Drive>,
    #[serde(default)]
    pub verified: bool,
    #[serde(default)]
    pub ejected: bool,
}

/// Why a USB write stopped before erasing anything, when the worker said.
/// It reports these on stdout as `ATLAS_ERROR:<reason>` before it throws.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FailureReason {
    /// The ISO is not supported Windows installation media.
    IsoUnsupported,
    /// The ISO or the app is on the USB drive, a network location or a link.
    SourceLocation,
    /// Too little free space to prepare the split Windows image.
    WorkingSpace,
    /// The prepared files do not fit the USB drive.
    DoesNotFit,
    /// The drive is no longer the one the list showed: removed, reconnected
    /// or replaced since.
    DriveChanged,
}

impl FailureReason {
    pub fn parse(value: &str) -> Option<Self> {
        Some(match value {
            "iso-unsupported" => Self::IsoUnsupported,
            "source-location" => Self::SourceLocation,
            "working-space" => Self::WorkingSpace,
            "does-not-fit" => Self::DoesNotFit,
            "drive-changed" => Self::DriveChanged,
            _ => return None,
        })
    }
}

#[derive(Debug)]
pub struct Failure {
    pub reason: Option<FailureReason>,
    /// The worker may have changed the drive: it went past preparing the
    /// files, or its output could not be read to the end to rule that out.
    pub drive_changed: bool,
    detail: String,
}

impl Failure {
    pub fn new(reason: Option<FailureReason>, drive_changed: bool, detail: impl Into<String>) -> Self {
        Self { reason, drive_changed, detail: detail.into() }
    }
}

impl std::fmt::Display for Failure {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?} (drive changed: {}): {}", self.reason, self.drive_changed, self.detail)
    }
}

impl std::error::Error for Failure {}

pub fn run(
    operation: &'static str,
    source: Option<&Path>,
    drive: Option<&Drive>,
    supported_builds: &[u32],
    dir: &Path,
    cancel: Arc<AtomicBool>,
    report: impl FnMut(Progress),
) -> Result<Outcome> {
    log::info!("USB operation {operation} started; diagnostics={}", dir.display());
    anyhow::ensure!(matches!(operation, "List" | "Write" | "Eject"), "unknown USB operation");
    if operation != "List" {
        anyhow::ensure!(drive.is_some(), "select a USB drive");
    }
    // Until the worker is running, nothing can have touched the drive.
    let (child, mut log) = start(operation, source, drive, supported_builds, dir)
        .map_err(|error| Failure::new(None, false, format!("{error:#}")))?;
    let (status, output) =
        powershell::follow_worker(child, dir, cancel, |stdout| read_output(stdout, &mut log, report))?;
    if !status.success() {
        return Err(Failure::new(
            output.reason,
            output.drive_changed,
            format!("USB worker failed; see {}", dir.join("usb.log").display()),
        )
        .into());
    }
    let outcome: Outcome = output.outcome.context("USB worker returned no result")?;
    anyhow::ensure!(operation != "Write" || outcome.verified, "USB was not verified");
    anyhow::ensure!(operation != "Eject" || outcome.ejected, "USB was not ejected");
    Ok(outcome)
}

/// What the worker reported on stdout.
struct Output {
    outcome: Option<Outcome>,
    reason: Option<FailureReason>,
    /// See [`Failure::drive_changed`].
    drive_changed: bool,
}

/// Reads the worker's markers to the end, copying every line to `log`.
fn read_output(stream: impl BufRead, log: &mut impl Write, mut report: impl FnMut(Progress)) -> Output {
    let mut output = Output { outcome: None, reason: None, drive_changed: false };
    // Nothing touches the drive before the worker moves past "prepare".
    let mut prepared_only = true;
    let read_all = powershell::read_lines(stream, log, |line| {
        if let Some(typed) = line.strip_prefix("ATLAS_ERROR:").and_then(FailureReason::parse) {
            output.reason = Some(typed);
        }
        if let Some(json) = line.strip_prefix("ATLAS_PROGRESS:")
            && let Ok(progress) = serde_json::from_str::<Progress>(json)
        {
            prepared_only &= progress.stage == "prepare";
            report(progress);
        }
        if let Some(json) = line.strip_prefix("ATLAS_RESULT:") {
            output.outcome = serde_json::from_str(json).ok();
        }
    });
    output.drive_changed = !(prepared_only && read_all);
    output
}

/// Stages the worker and its request in `dir` and starts the worker.
fn start(
    operation: &str,
    source: Option<&Path>,
    drive: Option<&Drive>,
    supported_builds: &[u32],
    dir: &Path,
) -> Result<(Child, fs::File)> {
    let request_json = serde_json::to_vec(&serde_json::json!({
        "source": source,
        "drive": drive,
        "app": std::env::current_exe()?,
        "eraseConfirmed": operation == "Write",
        "supportedBuilds": supported_builds,
    }))?;
    super::recovery_app::stage_media_job(
        dir,
        &[
            ("Write-Usb.ps1", include_str!("../../resources/iso/Write-Usb.ps1").as_bytes()),
            ("usb-request.json", &request_json),
        ],
    )?;
    let log = fs::File::create(dir.join("usb.log"))?;
    let child = powershell::start_worker(dir, "Write-Usb.ps1", "usb-request.json", operation, &log)
        .context("start USB worker")?;
    Ok((child, log))
}

pub fn preview_drive() -> Drive {
    Drive {
        number: 2,
        name: "Kingston DataTraveler Max".into(),
        serial: "USB-PREVIEW".into(),
        unique_id: "preview".into(),
        path: "preview".into(),
        size: 256_060_514_304,
        volumes: "F: USB".into(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn usb_inventory_worker_returns_typed_results_without_writing_a_drive() {
        let dir = crate::services::test_support::TempDir::new("usb-inventory");
        let result = run("List", None, None, &[], dir.path(), Arc::new(AtomicBool::new(false)), |_| {})
            .expect("read the Windows USB inventory");
        assert!(!result.verified && !result.ejected);
        assert!(result.drives.iter().all(|drive| !drive.unique_id.is_empty() && !drive.path.is_empty()));
    }

    #[test]
    fn failure_reasons_match_the_worker_markers() {
        // Every marker the worker writes must be understood here, or the page
        // falls back to generic advice.
        let script = include_str!("../../resources/iso/Write-Usb.ps1");
        let markers: Vec<_> = script
            .lines()
            .filter_map(|line| {
                let start = line.find("Fail '")? + "Fail '".len();
                line[start..].split('\'').next()
            })
            .collect();
        assert!(!markers.is_empty());
        for marker in &markers {
            assert!(FailureReason::parse(marker).is_some(), "unknown worker marker {marker:?}");
        }
        assert!(markers.contains(&"drive-changed"));
    }

    #[test]
    fn a_badly_encoded_line_hides_neither_the_reason_nor_the_result() {
        let mut stages = vec![];
        let output = read_output(
            &b"ATLAS_PROGRESS:{\"stage\":\"prepare\",\"done\":0,\"total\":0}\r\nE: Donn\x82es\r\nATLAS_ERROR:does-not-fit\r\nATLAS_RESULT:{\"drives\":[]}\r\n"[..],
            &mut Vec::new(),
            |progress| stages.push(progress.stage),
        );
        assert_eq!(stages, ["prepare"]);
        assert_eq!(output.reason, Some(FailureReason::DoesNotFit));
        assert!(output.outcome.is_some());
        assert!(!output.drive_changed, "the worker only prepared files");
        let formatting = read_output(
            &b"ATLAS_PROGRESS:{\"stage\":\"prepare\",\"done\":0,\"total\":0}\nATLAS_PROGRESS:{\"stage\":\"format\",\"done\":0,\"total\":0}\n"[..],
            &mut Vec::new(),
            |_| {},
        );
        assert!(formatting.drive_changed);
    }

    /// The empty-list text quotes these limits; the worker applies them.
    #[test]
    fn drive_size_limits_match_the_worker() {
        let script = include_str!("../../resources/iso/Write-Usb.ps1");
        let limit = |pattern: &str| -> u64 {
            regex::Regex::new(pattern).unwrap().captures(script).expect(pattern)[1].parse().unwrap()
        };
        assert_eq!(limit(r"\$Disk\.Size -ge (\d+)GB") << 30, MIN_BYTES);
        assert_eq!(limit(r"\$Disk\.Size -le (\d+)TB") << 40, MAX_BYTES);
    }

    #[test]
    fn usb_progress_stops_at_complete_and_unknown_totals_are_indeterminate() {
        assert_eq!(Progress::default().fraction(), None);
        assert_eq!(Progress { done: 5, total: 10, ..Default::default() }.fraction(), Some(0.5));
        assert_eq!(Progress { done: 11, total: 10, ..Default::default() }.fraction(), Some(1.));
    }
}
