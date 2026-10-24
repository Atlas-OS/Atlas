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

/// Stages the worker, the libraries it dot-sources and the driver policy in a
/// protected job directory.
pub fn stage_preparation(
    job: &Path,
    worker: &str,
    library: &str,
    registry: &str,
    policy: &[u8],
) -> Result<()> {
    let (scope, name) = job_names(job)?;
    invoke_for(
        job,
        serde_json::json!({"operation":"preparation", "scope":scope, "job":name, "worker":worker, "library":library, "registry":registry, "policy":policy}),
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

/// Run with `-Command`, the request on its input.
const STAGE_APP: &str = include_str!("../../resources/prepare/Stage-App.ps1");

/// Stage-App.ps1's exit code when Atlas Manager was started from a linked
/// folder, which moving it fixes.
const SOURCE_LINKED_EXIT_CODE: i32 = 2;

/// Atlas Manager was started from a folder reached through a junction or
/// symbolic link, which staging refuses. Moving it to a folder that isn't
/// linked fixes it.
#[derive(Debug)]
pub struct SourceLinked(pub String);

impl std::fmt::Display for SourceLinked {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "recovery staging failed: {}", self.0)
    }
}

impl std::error::Error for SourceLinked {}

fn invoke(request: serde_json::Value) -> Result<PathBuf> {
    run_staging(STAGE_APP, &request)
}

/// Runs a staging script with `request` on its input and reads the path it
/// answers with.
fn run_staging(script: &str, request: &serde_json::Value) -> Result<PathBuf> {
    let mut child = powershell::command()
        .arg("-Command")
        .arg(script)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .context("start the recovery staging")?;
    let request = serde_json::to_vec(request)?;
    child.stdin.take().context("recovery staging input")?.write_all(&request)?;
    let output = child.wait_with_output()?;
    if output.status.code() == Some(SOURCE_LINKED_EXIT_CODE) {
        return Err(SourceLinked(String::from_utf8_lossy(&output.stderr).trim().to_owned()).into());
    }
    anyhow::ensure!(
        output.status.success(),
        "recovery staging failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    serde_json::from_slice(&output.stdout).context("read staged recovery path")
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A linked source is told apart from every other staging failure, by the
    /// exit code Stage-App.ps1 itself uses for it.
    #[test]
    fn a_linked_source_is_its_own_error() {
        let code = format!("$AtlasSourceLinkedExitCode = {SOURCE_LINKED_EXIT_CODE}");
        assert!(
            STAGE_APP.contains(&code),
            "Stage-App.ps1 no longer exits {SOURCE_LINKED_EXIT_CODE} for a link"
        );
        let request = serde_json::json!({"operation": "executable"});
        let stub = |message: &str, code: i32| {
            format!("$null = [Console]::In.ReadToEnd(); [Console]::Error.WriteLine('{message}'); exit {code}")
        };
        let error = run_staging(&stub("linked folder", SOURCE_LINKED_EXIT_CODE), &request).unwrap_err();
        let linked = error.downcast_ref::<SourceLinked>().expect("a linked source");
        assert_eq!(linked.0, "linked folder");
        assert_eq!(error.to_string(), "recovery staging failed: linked folder");
        let other = run_staging(&stub("denied", 1), &request).unwrap_err();
        assert!(!other.is::<SourceLinked>(), "{other:#}");
    }
}
