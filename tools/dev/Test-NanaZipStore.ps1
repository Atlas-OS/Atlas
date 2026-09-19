<#
.SYNOPSIS
    Probe NanaZip through the official WinGet COM-backed PowerShell module.
.DESCRIPTION
    Read-only package lookup by default. Use -Install only on a disposable test
    machine. Installs the Store version for all users and checks provisioning.
    This experiment does not run download fallbacks or uninstall existing apps.
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ClientManifest,
    [string]$OutputDirectory = (Join-Path $PWD 'artifacts\store-probe\runs'),
    [ValidateRange(1, 1800)][int]$TimeoutSeconds = 180,
    [switch]$Install
)
$ErrorActionPreference = 'Stop'
$ClientManifest = (Resolve-Path -LiteralPath $ClientManifest).Path
$runDirectory = Join-Path $OutputDirectory ([guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $runDirectory -Force
$reportPath = Join-Path (Resolve-Path $runDirectory).Path 'report.json'
$modulePath = Join-Path $PSScriptRoot 'NanaZipStoreProbe.psm1'
$doInstall = [bool]$Install
$job = Start-Job -ScriptBlock {
    Import-Module $using:modulePath -ErrorAction Stop
    Invoke-NanaZipStoreProbe -ClientManifest $using:ClientManifest -ReportPath $using:reportPath -Install:$using:doInstall
}
try {
    if (-not (Wait-Job $job -Timeout $TimeoutSeconds)) {
        # Stopping the client does not prove the Store service cancelled its work.
        Stop-Job $job
        $timeoutReport = [ordered]@{ Decision = 'InspectBeforeRetry'; Error = 'Client timed out; Store operation completion is unknown.' }
        if (Test-Path -LiteralPath $reportPath) {
            $timeoutReport = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
            $timeoutReport.Decision = 'InspectBeforeRetry'
            $timeoutReport.Error = 'Client timed out; Store operation completion is unknown.'
        }
        $timeoutReport | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8
    }
    Receive-Job $job -ErrorAction Continue | Out-Null
    if (-not (Test-Path -LiteralPath $reportPath)) { throw 'Probe worker failed before creating a report.' }
    $reportJson = Get-Content -LiteralPath $reportPath -Raw
    $reportJson
    $finalReport = $reportJson | ConvertFrom-Json
    Write-Host "Report saved to $reportPath"
}
finally {
    if ($job.State -eq 'Running') { Stop-Job $job }
    Remove-Job $job -Force
}
if ($finalReport.Decision -notin @('ProbeOnly', 'Installed', 'AlreadyProvisioned')) { exit 2 }
