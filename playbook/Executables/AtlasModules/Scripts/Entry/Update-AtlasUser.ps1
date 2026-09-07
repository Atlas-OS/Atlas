<#
.SYNOPSIS
    Applies upgraded user settings without resetting the user's desktop layout.
#>
[CmdletBinding()]
param([string]$ExpectedUserSid)

$scriptsRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $scriptsRoot 'Initialize-AtlasPowerShell.ps1')
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$actualSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
if (-not $ExpectedUserSid) {
    $eligible = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\AtlasOS\UpgradeUsers' -Name $actualSid -ErrorAction SilentlyContinue
    if ($null -eq $eligible) { return }
}
if ($ExpectedUserSid -and $actualSid -cne $ExpectedUserSid) { throw 'Upgrade user token does not match the installing user.' }
foreach ($module in 'Atlas.Core', 'Atlas.Registry', 'Atlas.Tweaks', 'Atlas.Toggles') {
    Import-Module (Join-Path $scriptsRoot "Modules\$module\$module.psd1") -ErrorAction Stop
}
if ((Test-AtlasSystem) -or (Test-AtlasAdmin)) { throw 'User upgrade requires the affected non-elevated user.' }
$context = Get-AtlasContext -Refresh
$context.IsUpgrade = $true
$version = if ($context.IsInstallStateBacked) { [string]$context.TargetVersion } else { [string]$context.InstalledVersion }
if ([string]::IsNullOrWhiteSpace($version)) { throw 'Installed version is unavailable for user migration.' }
$markerPath = 'HKCU:\SOFTWARE\AtlasOS\UserSetup'
$markerName = 'UpgradeVersion'
$completed = Get-ItemProperty -LiteralPath $markerPath -Name $markerName -ErrorAction SilentlyContinue
if (-not $ExpectedUserSid -and $null -ne $completed -and $completed.$markerName -ceq $version) { return }
$logRoot = Join-Path $env:LOCALAPPDATA 'AtlasOS\Logs'
$null = New-Item -Path $logRoot -ItemType Directory -Force
Start-Transcript -Path (Join-Path $logRoot ('{0:yyyyMMdd-HHmmss}-upgrade-user-{1}.log' -f (Get-Date), $PID)) | Out-Null
try {
    $null = Initialize-AtlasRegistryIdentityContext -CurrentToken -ExpectedUserSid $actualSid
    # The installing-user pass already handles protected policy roots. Later logons
    # apply ordinary HKCU settings under that user's own token.
    foreach ($category in 'networking', 'performance', 'privacy', 'qol', 'security', 'debloat', 'scripts', 'misc') {
        Invoke-AtlasTweakCategory -Name $category -RegistryScope CurrentUser -RegistryOnly -Context $context
    }
    Invoke-AtlasToggleUserReapply
    $null = New-Item -Path $markerPath -Force
    New-ItemProperty -LiteralPath $markerPath -Name $markerName -Value $version -PropertyType String -Force | Out-Null
}
finally { Stop-Transcript | Out-Null }
