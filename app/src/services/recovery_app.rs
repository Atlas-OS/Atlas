//! Protected copies under Program Files that only administrators can change:
//! the executable that reopens Atlas after a restart, and the preparation and
//! media job directories elevated workers load from. Stage-App.ps1 does the
//! copying and sets the permissions.

use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Stdio;

use anyhow::{Context, Result};

use super::powershell;

pub fn preparation_root(settings: &Path) -> Result<PathBuf> {
    protected_root(settings, "Preparation")
}

/// Job directories for the elevated ISO and USB workers.
pub fn media_root(settings: &Path) -> Result<PathBuf> {
    protected_root(settings, "Media")
}

fn protected_root(settings: &Path, kind: &str) -> Result<PathBuf> {
    if cfg!(test) {
        return Ok(settings.parent().context("settings directory")?.join(kind));
    }
    use windows::Win32::{
        System::Com::CoTaskMemFree,
        UI::Shell::{FOLDERID_ProgramFiles, KF_FLAG_DEFAULT, SHGetKnownFolderPath},
    };
    let path = unsafe { SHGetKnownFolderPath(&FOLDERID_ProgramFiles, KF_FLAG_DEFAULT, None) }?;
    let text = unsafe { path.to_string() };
    unsafe { CoTaskMemFree(Some(path.0.cast())) };
    // One root per app-data directory, so different users (or runs with
    // ATLAS_APP_DATA) never share jobs.
    let scope = super::releases::sha256_bytes(settings.as_os_str().to_string_lossy().as_bytes());
    Ok(PathBuf::from(text?).join("Atlas Setup Recovery").join(kind).join(scope))
}

// Tests never stage into Program Files; Stage-App.ps1 is tested on its own.
#[cfg(test)]
pub fn stage() -> Result<PathBuf> {
    std::env::current_exe().context("locate the test executable")
}

#[cfg(not(test))]
pub fn stage() -> Result<PathBuf> {
    let source = std::env::current_exe().context("locate Atlas for restart recovery")?;
    if super::desktop_setup::active() {
        return Ok(source);
    }
    invoke(serde_json::json!({"operation":"executable", "source":source}))
}

pub fn stage_preparation(job: &Path, worker: &str, policy: &[u8]) -> Result<()> {
    let (scope, name) = job_names(job)?;
    invoke_for(
        job,
        serde_json::json!({"operation":"preparation", "scope":scope, "job":name, "worker":worker, "policy":policy}),
    )
}

/// Creates a media job directory that only administrators can change, with
/// the scripts and request an elevated worker will load from it.
pub fn stage_media_job(job: &Path, files: &[(&str, &[u8])]) -> Result<()> {
    if cfg!(test) {
        std::fs::create_dir_all(job)?;
        for (name, bytes) in files {
            std::fs::write(job.join(name), bytes)?;
        }
        return Ok(());
    }
    let (scope, name) = job_names(job)?;
    let files: Vec<_> =
        files.iter().map(|(name, bytes)| serde_json::json!({"name":name, "bytes":bytes})).collect();
    invoke_for(job, serde_json::json!({"operation":"media", "scope":scope, "job":name, "files":files}))
}

/// Confirms `job` is a preparation job directory that staging created.
pub fn validate_preparation(job: &Path) -> Result<()> {
    if cfg!(test) {
        return Ok(());
    }
    let (scope, name) = job_names(job)?;
    invoke_for(job, serde_json::json!({"operation":"validate-preparation", "scope":scope, "job":name}))
}

/// The scope and job directory names Stage-App.ps1 rebuilds a job's path from.
fn job_names(job: &Path) -> Result<(String, String)> {
    let name = |path: &Path| path.file_name().map(|name| name.to_string_lossy().into_owned());
    let scope = job.parent().and_then(name).context("the job's scope")?;
    Ok((scope, name(job).context("the job's name")?))
}

/// Runs a Stage-App.ps1 operation for `job` and checks that it answered with
/// that same directory.
fn invoke_for(job: &Path, request: serde_json::Value) -> Result<()> {
    let actual = invoke(request)?;
    anyhow::ensure!(
        actual == job,
        "recovery staging answered {} instead of {}",
        actual.display(),
        job.display()
    );
    Ok(())
}

fn invoke(request: serde_json::Value) -> Result<PathBuf> {
    let mut child = powershell::command()
        .arg("-Command")
        .arg(include_str!("../../resources/prepare/Stage-App.ps1"))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .context("start the recovery staging")?;
    let request = serde_json::to_vec(&request)?;
    child.stdin.take().context("recovery staging input")?.write_all(&request)?;
    let output = child.wait_with_output()?;
    anyhow::ensure!(
        output.status.success(),
        "recovery staging failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    serde_json::from_slice(&output.stdout).context("read staged recovery path")
}
