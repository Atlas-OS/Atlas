# Shell refresh phase, in every install mode after pre-install. TrustedInstaller only
# orchestrates: stopping the shell and starting Explorer run as the installing user, in
# that user's Windows session, so other console or remote sessions are never affected.

Assert-AtlasPrivilege -TrustedInstaller

$context = Get-AtlasContext -Refresh
if (-not $context.IsInstallStateBacked) {
    throw 'Shell refresh requires an active Atlas install state.'
}
$interactiveUserSid = [string]$context.InteractiveUserSid
if ([string]::IsNullOrWhiteSpace($interactiveUserSid)) {
    throw 'Shell refresh requires the install-state user SID.'
}

$scriptsRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$shellRefreshScript = Join-Path -Path $scriptsRoot `
    -ChildPath 'Operations\Invoke-AtlasUserShellRefresh.ps1'
if (-not [IO.File]::Exists($shellRefreshScript)) {
    throw "The exact-user shell refresh helper is missing at '$shellRefreshScript'."
}

$powerShellPath = [IO.Path]::Combine(
    [Environment]::SystemDirectory,
    'WindowsPowerShell',
    'v1.0',
    'powershell.exe'
)

# The helper runs in the user's session, where its errors never reach this console, so a
# failure leaves its error and script position in a record named for this run.
$failureRecordId = [guid]::NewGuid().ToString('N')
$arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -ExpectedUserSid "{1}" -FailureRecordId {2}' -f `
    $shellRefreshScript,
    $interactiveUserSid,
    $failureRecordId
$exitCode = Invoke-AtlasAsUser -FilePath $powerShellPath -Arguments $arguments `
    -WorkingDirectory ([string]$context.WinDir)
if ($exitCode -ne 0) {
    $failureStage = Get-AtlasUserSessionHelperStage -ExitCode $exitCode
    if ($null -eq $failureStage) {
        $failureStage = 'unknown stage'
    }
    . (Join-Path $scriptsRoot 'Install\Tasks\Get-AtlasUserFailureDetail.ps1')
    $failureDetail = Get-AtlasUserFailureDetail -UserSid $interactiveUserSid `
        -TranscriptPattern "shell-refresh-$failureRecordId.log"
    throw "Exact-user shell refresh failed during $failureStage (exit code $exitCode).$failureDetail"
}
