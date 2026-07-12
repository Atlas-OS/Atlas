# Shell refresh phase.
# TrustedInstaller owns orchestration only. Shell termination and Explorer startup are
# delegated to the exact install-state-bound medium user and constrained to that token's
# Windows session so other console/RDP sessions are never affected.

Assert-AtlasPrivilege -TrustedInstaller

$context = Get-AtlasContext -Refresh
if (-not $context.IsInstallStateBacked -or $context.IsOobe) {
    throw 'Shell refresh requires a non-OOBE active Atlas install state.'
}
$interactiveUserSid = [string]$context.InteractiveUserSid
if ([string]::IsNullOrWhiteSpace($interactiveUserSid)) {
    throw 'Shell refresh requires the install-state user SID.'
}

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$shellRefreshScript = Join-Path -Path $scriptsRoot `
    -ChildPath 'Internal\Invoke-AtlasUserShellRefresh.ps1'
if (-not [IO.File]::Exists($shellRefreshScript)) {
    throw "The exact-user shell refresh helper is missing at '$shellRefreshScript'."
}

$powerShellPath = [IO.Path]::Combine(
    [Environment]::SystemDirectory,
    'WindowsPowerShell',
    'v1.0',
    'powershell.exe'
)

$arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -ExpectedUserSid "{1}"' -f `
    $shellRefreshScript,
    $interactiveUserSid
$exitCode = Invoke-AtlasAsUser -FilePath $powerShellPath -Arguments $arguments `
    -WorkingDirectory ([string]$context.WinDir)
if ($exitCode -ne 0) {
    $failureStage = switch ($exitCode) {
        10 { 'bootstrap' }
        11 { 'identity validation' }
        12 { 'process stop' }
        13 { 'Explorer start' }
        14 { 'Explorer recovery' }
        default { 'unknown stage' }
    }
    throw "Exact-user shell refresh failed during $failureStage (exit code $exitCode)."
}
