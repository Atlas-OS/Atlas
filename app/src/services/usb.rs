//! A Windows installation USB writer, never a raw ISO-to-disk copy.
use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};
use std::{
    fs,
    io::{BufRead, BufReader, Write},
    path::Path,
    process::{Command, Stdio},
    sync::{
        Arc,
        atomic::{AtomicBool, Ordering},
    },
};

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

pub fn run(
    operation: &'static str,
    source: Option<&Path>,
    drive: Option<&Drive>,
    dir: &Path,
    cancel: Arc<AtomicBool>,
    mut report: impl FnMut(Progress),
) -> Result<Outcome> {
    log::info!("USB operation {operation} started; diagnostics={}", dir.display());
    anyhow::ensure!(matches!(operation, "List" | "Write" | "Eject"), "Unknown USB operation");
    if operation != "List" {
        anyhow::ensure!(drive.is_some(), "Select a USB drive");
    }
    let script = dir.join("Write-Usb.ps1");
    let request = dir.join("usb-request.json");
    fs::write(&script, include_str!("../../resources/iso/Write-Usb.ps1"))?;
    fs::write(
        &request,
        serde_json::to_vec(&serde_json::json!({
            "source": source,
            "drive": drive,
            "app": std::env::current_exe()?,
            "eraseConfirmed": operation == "Write",
        }))?,
    )?;
    let mut log = fs::File::create(dir.join("usb.log"))?;
    let mut command = Command::new(super::system::powershell_path());
    command
        .args(["-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File"])
        .arg(script)
        .arg("-RequestFile")
        .arg(request)
        .arg("-Operation")
        .arg(operation)
        .stdout(Stdio::piped())
        .stderr(Stdio::from(log.try_clone()?));
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        command.creation_flags(0x08000000);
    }
    let mut child = command.spawn().context("start USB worker")?;
    let stream = child.stdout.take().context("USB worker stdout")?;
    let flag = dir.join("cancel");
    let stop = Arc::new(AtomicBool::new(false));
    let watcher = super::system::watch_cancellation(cancel, stop.clone(), flag);
    let mut outcome = None;
    for line in BufReader::new(stream).lines() {
        let Ok(line) = line else { break };
        let _ = writeln!(log, "{line}");
        if let Some(json) = line.strip_prefix("ATLAS_PROGRESS:")
            && let Ok(progress) = serde_json::from_str(json)
        {
            report(progress);
        }
        if let Some(json) = line.strip_prefix("ATLAS_RESULT:") {
            outcome = serde_json::from_str(json).ok();
        }
    }
    let exit = child.wait();
    stop.store(true, Ordering::Relaxed);
    let _ = watcher.join();
    if !exit?.success() {
        bail!("USB worker failed; see {}", dir.join("usb.log").display());
    }
    let outcome: Outcome = outcome.context("USB worker returned no result")?;
    anyhow::ensure!(operation != "Write" || outcome.verified, "USB was not verified");
    anyhow::ensure!(operation != "Eject" || outcome.ejected, "USB was not ejected");
    Ok(outcome)
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
        let dir = super::super::test_support::TempDir::new("usb-inventory");
        let result = run("List", None, None, dir.path(), Arc::new(AtomicBool::new(false)), |_| {})
            .expect("read the Windows USB inventory");
        assert!(!result.verified && !result.ejected);
        assert!(result.drives.iter().all(|drive| !drive.unique_id.is_empty() && !drive.path.is_empty()));
    }

    #[test]
    fn usb_progress_is_bounded_and_unknown_totals_are_indeterminate() {
        assert_eq!(Progress::default().fraction(), None);
        assert_eq!(Progress { done: 5, total: 10, ..Default::default() }.fraction(), Some(0.5));
        assert_eq!(Progress { done: 11, total: 10, ..Default::default() }.fraction(), Some(1.));
    }
}
