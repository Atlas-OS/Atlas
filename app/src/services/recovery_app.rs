//! An immutable, protected local executable for preparation and installation restarts.
use anyhow::{Context, Result};
use std::path::PathBuf;

pub fn preparation_root(settings: &std::path::Path) -> Result<PathBuf> {
    if cfg!(test) {
        return Ok(settings.parent().context("settings directory")?.join("Preparation"));
    }
    use windows::Win32::{
        System::Com::CoTaskMemFree,
        UI::Shell::{FOLDERID_ProgramFiles, KF_FLAG_DEFAULT, SHGetKnownFolderPath},
    };
    let path = unsafe { SHGetKnownFolderPath(&FOLDERID_ProgramFiles, KF_FLAG_DEFAULT, None) }?;
    let text = unsafe { path.to_string() };
    unsafe { CoTaskMemFree(Some(path.0.cast())) };
    let scope: String =
        ring::digest::digest(&ring::digest::SHA256, settings.as_os_str().to_string_lossy().as_bytes())
            .as_ref()
            .iter()
            .map(|byte| format!("{byte:02x}"))
            .collect();
    Ok(PathBuf::from(text?).join("Atlas Setup Recovery/Preparation").join(scope))
}

// Headless installation fixtures never stage into the host's Program Files.
// The real copy/ACL implementation is exercised separately in PowerShell fixtures.
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

pub fn stage_preparation(job: &std::path::Path, worker: &str, policy: &[u8]) -> Result<()> {
    let scope = job.parent().and_then(|p| p.file_name()).context("preparation scope")?.to_string_lossy();
    let name = job.file_name().context("preparation job")?.to_string_lossy();
    let actual = invoke(
        serde_json::json!({"operation":"preparation", "scope":scope,"job":name,"worker":worker,"policy":policy}),
    )?;
    anyhow::ensure!(actual == job, "Windows staged preparation at an unexpected location");
    Ok(())
}

pub fn validate_preparation(job: &std::path::Path) -> Result<()> {
    if cfg!(test) {
        return Ok(());
    }
    let scope = job.parent().and_then(|p| p.file_name()).context("preparation scope")?.to_string_lossy();
    let name = job.file_name().context("preparation job")?.to_string_lossy();
    let actual = invoke(serde_json::json!({"operation":"validate-preparation", "scope":scope,"job":name}))?;
    anyhow::ensure!(actual == job, "Unexpected preparation recovery location");
    Ok(())
}

fn invoke(request: serde_json::Value) -> Result<PathBuf> {
    use anyhow::ensure;
    use std::{
        io::Write,
        process::{Command, Stdio},
    };
    let mut command = Command::new(super::system::powershell_path());
    command
        .args(["-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"])
        .arg(include_str!("../../resources/prepare/Stage-App.ps1"))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        command.creation_flags(0x08000000);
    }
    let mut child = command.spawn().context("stage a local recovery executable")?;
    let request = serde_json::to_vec(&request)?;
    child.stdin.take().context("recovery staging input")?.write_all(&request)?;
    let output = child.wait_with_output()?;
    ensure!(output.status.success(), "recovery staging failed: {}", String::from_utf8_lossy(&output.stderr));
    serde_json::from_slice(&output.stdout).context("read staged recovery path")
}
