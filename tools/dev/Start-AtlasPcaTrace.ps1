<#
.SYNOPSIS
    Prepares an installed Atlas VM to trace PcaPatchDbTask re-enablement across reboot.
.DESCRIPTION
    Run elevated inside the affected VM. Enables Task Scheduler operational history,
    disables only PcaPatchDbTask, verifies its immediate state, and saves a transcript.
    Does not reboot. After reboot, collect Get-AtlasInstallReport.ps1 -RcDiagnostics.
    Task history remains enabled for collection; the transcript records its old state.
.PARAMETER OutputDirectory
    Directory for the timestamped trace transcript. Defaults to this account's Desktop.
#>
[CmdletBinding()]
param(
    [string]$OutputDirectory = [Environment]::GetFolderPath('DesktopDirectory')
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this diagnostic from an elevated Windows PowerShell prompt in the affected Atlas VM.'
}
$statePath = Join-Path ([Environment]::GetFolderPath('Windows')) 'AtlasOS\state.json'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw 'Atlas install state is missing. Run this diagnostic inside the installed Atlas VM.'
}
$taskPath = '\Microsoft\Windows\Application Experience\'
$taskName = 'PcaPatchDbTask'
$logName = 'Microsoft-Windows-TaskScheduler/Operational'
$task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
$log = Get-WinEvent -ListLog $logName -ErrorAction Stop
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { throw 'An output directory is required.' }
$null = New-Item -Path $OutputDirectory -ItemType Directory -Force
$transcript = Join-Path $OutputDirectory ('atlas-pca-trace-{0:yyyyMMdd-HHmmss}.txt' -f (Get-Date))
Start-Transcript -LiteralPath $transcript -ErrorAction Stop | Out-Null
try {
    Write-Host "Trace starts: $((Get-Date).ToString('o')); machine: $env:COMPUTERNAME"
    Write-Host "Task history originally enabled: $($log.IsEnabled)"
    Write-Host "Task originally enabled: $($task.Settings.Enabled)"
    Export-ScheduledTask -TaskPath $taskPath -TaskName $taskName
    $wevtutil = Join-Path ([Environment]::SystemDirectory) 'wevtutil.exe'
    & $wevtutil sl $logName /e:true
    if ($LASTEXITCODE -ne 0) { throw "Enabling task history failed with exit code $LASTEXITCODE." }
    if (-not (Get-WinEvent -ListLog $logName -ErrorAction Stop).IsEnabled) {
        throw 'Task history is still disabled.'
    }
    Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop | Out-Null
    $verifiedTask = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
    if ($verifiedTask.Settings.Enabled) { throw 'PcaPatchDbTask did not remain disabled immediately after the change.' }
    Write-Host "Verified disabled at $((Get-Date).ToString('o'))."
    Write-Host 'Reboot this VM, then run Get-AtlasInstallReport.ps1 -RcDiagnostics.'
    Write-Host 'Keep this transcript alongside the report.'
    if (-not $log.IsEnabled) {
        Write-Host 'After collecting the report, restore the previous history setting with:'
        Write-Host 'wevtutil sl Microsoft-Windows-TaskScheduler/Operational /e:false'
    }
}
finally { Stop-Transcript | Out-Null }
