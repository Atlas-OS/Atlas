//! The command that runs the front door: the option names it accepts, the
//! PowerShell statement that calls it and the go-ahead wrapper around that.

use std::path::Path;

use anyhow::Result;

use super::{InstallRequest, NOT_STARTED_EXIT_CODE};
use crate::services::{playbook, powershell};

/// Whether `name` has the shape the front door accepts for an option
/// (`^[a-z0-9-]+$`). Option names are spliced into a PowerShell array
/// literal, so nothing else may get that far.
pub fn valid_option_name(name: &str) -> bool {
    !name.is_empty() && name.bytes().all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-')
}

/// At least one option, and every name valid.
pub fn validate_options(options: &[String]) -> Result<()> {
    anyhow::ensure!(!options.is_empty(), "no install options were chosen");
    for option in options {
        anyhow::ensure!(valid_option_name(option), "{option:?} is not a valid option name");
    }
    Ok(())
}

/// Single-quoted PowerShell string literal; the only escape is a doubled quote.
fn ps_quote(text: &str) -> String {
    format!("'{}'", text.replace('\'', "''"))
}

/// A path as Windows PowerShell 5.1 accepts it, without the `\\?\` prefix.
fn plain_path(path: &Path) -> String {
    playbook::plain_path(path.to_path_buf()).to_string_lossy().into_owned()
}

/// The call to the front door, as a PowerShell statement. Atlas restarts
/// Windows itself, so the front door is never asked to.
fn script_call(request: &InstallRequest) -> Result<String> {
    validate_options(&request.options)?;
    let script = playbook::front_door(&request.playbook_dir);
    let options = request.options.iter().map(|o| ps_quote(o)).collect::<Vec<_>>().join(",");
    Ok(format!("& {} -Option @({options}) -Unattended", ps_quote(&plain_path(&script))))
}

/// What the child runs. It first waits for the go-ahead file, which the app
/// creates only once the session record is written, so the front door never
/// runs without a record that a reopened app can find; a go-ahead that never
/// comes is written as [`NOT_STARTED_EXIT_CODE`]. Then: UTF-8 output, the
/// front door, and the exit code written where the session can find it.
/// `-Command` is used instead of `-File` because `-File` passes every
/// argument as one string, which cannot express the script's `[string[]]`
/// option list.
pub(super) fn wrapper_command(
    request: &InstallRequest,
    exit_path: &Path,
    go_path: &Path,
    handover_timeout_seconds: u32,
) -> Result<String> {
    Ok(format!(
        "$atlasGo = {go}; $atlasDeadline = (Get-Date).AddSeconds({timeout}); while (-not (Test-Path -LiteralPath $atlasGo)) {{ if ((Get-Date) -gt $atlasDeadline) {{ [IO.File]::WriteAllText({exit}, '{not_started}'); exit {not_started} }}; Start-Sleep -Milliseconds 50 }}; [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false); {call}; $atlasExit = $LASTEXITCODE; if ($null -eq $atlasExit) {{ $atlasExit = 1 }}; [IO.File]::WriteAllText({exit}, [string]$atlasExit); exit $atlasExit",
        go = ps_quote(&plain_path(go_path)),
        timeout = handover_timeout_seconds,
        not_started = NOT_STARTED_EXIT_CODE,
        call = script_call(request)?,
        exit = ps_quote(&plain_path(exit_path)),
    ))
}

/// The front door call the installer runs for `request`, as shown to the
/// user (without the go-ahead wrapper around it).
pub fn command_line(request: &InstallRequest) -> Result<String> {
    Ok(format!("powershell.exe {} -Command \"{}\"", powershell::FLAGS.join(" "), script_call(request)?))
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    use super::*;

    #[test]
    fn options_are_held_to_the_scripts_pattern() {
        assert!(validate_options(&["defender-enable".into(), "auto-updates-disable".into()]).is_ok());
        assert!(validate_options(&[]).is_err());
        assert!(validate_options(&["".into()]).is_err());
        assert!(validate_options(&["a,b".into()]).is_err());
        assert!(validate_options(&["Defender".into()]).is_err());
        assert!(validate_options(&["a'b".into()]).is_err());
        assert!(validate_options(&["a b".into()]).is_err());
    }

    #[test]
    fn the_command_passes_a_real_array_and_quotes_paths() {
        let request = InstallRequest {
            playbook_dir: PathBuf::from(r"C:\Users\O'Brien\AtlasOS\App\Playbooks\0.6.0"),
            options: vec!["defender-enable".into(), "mitigations-default".into()],
            restart: true,
        };
        // What is shown is what the child runs, and Atlas owns the restart.
        assert_eq!(
            command_line(&request).unwrap(),
            r#"powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& 'C:\Users\O''Brien\AtlasOS\App\Playbooks\0.6.0\Executables\AtlasModules\Scripts\Entry\Install-Atlas.ps1' -Option @('defender-enable','mitigations-default') -Unattended""#
        );
    }

    /// Every launch passes `-Option` and `-Unattended`, so the real front door
    /// must keep declaring them.
    #[test]
    fn the_front_door_declares_the_parameters_every_launch_passes() {
        let script =
            include_str!("../../../../playbook/Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1");
        let block = script
            .split_once("\nparam(")
            .and_then(|(_, rest)| rest.split_once("\n)"))
            .map(|(block, _)| block)
            .expect("the script's parameter block");
        assert!(block.contains("[string[]]$Option"), "{block}");
        assert!(block.contains("[switch]$Unattended"), "{block}");
    }
}
