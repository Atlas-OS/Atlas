<#
.SYNOPSIS
    Applies upgraded user settings without resetting the user's desktop layout.
#>
[CmdletBinding()]
param([string]$ExpectedUserSid)

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($PSScriptRoot))
$bootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($bootstrap)) { throw "The PowerShell bootstrap is missing at '$bootstrap'." }
. $bootstrap
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$actualSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
# The install that last changed Atlas stamped this account (Set-AtlasUpgradeUserStamp).
$eligible = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\AtlasOS\UpgradeUsers' -Name $actualSid -ErrorAction SilentlyContinue
if (-not $ExpectedUserSid -and $null -eq $eligible) { return }
if ($ExpectedUserSid -and $actualSid -cne $ExpectedUserSid) { throw 'Upgrade user token does not match the installing user.' }
foreach ($module in 'Atlas.Core', 'Atlas.Registry', 'Atlas.Tweaks', 'Atlas.Toggles') {
    Import-Module (Join-Path $scriptsRoot "Modules\$module\$module.psd1") -ErrorAction Stop
}
if ((Test-AtlasSystem) -or (Test-AtlasAdmin)) { throw 'User upgrade requires the affected non-elevated user.' }
$context = Get-AtlasContext -Refresh
$context.IsUpgrade = $true
$version = if ($context.IsInstallStateBacked) { [string]$context.TargetVersion } else { [string]$context.InstalledVersion }
if ([string]::IsNullOrWhiteSpace($version)) { throw 'Installed version is unavailable for user migration.' }
# An account runs once for each stamp: an update's is its version, and a reinstall of
# the same version adds its transaction. The installing user's own pass records the
# stamp as well, so its next sign-in doesn't run again.
$stamp = $version
if ($null -ne $eligible -and $eligible.$actualSid -is [string] -and -not [string]::IsNullOrWhiteSpace($eligible.$actualSid)) {
    $stamp = [string]$eligible.$actualSid
}
$markerPath = 'HKCU:\SOFTWARE\AtlasOS\UserSetup'
$markerName = 'UpgradeVersion'
$completed = Get-ItemProperty -LiteralPath $markerPath -Name $markerName -ErrorAction SilentlyContinue
if (-not $ExpectedUserSid -and $null -ne $completed -and $completed.$markerName -ceq $stamp) { return }
$logRoot = Join-Path $env:LOCALAPPDATA 'AtlasOS\Logs'
$null = New-Item -Path $logRoot -ItemType Directory -Force
Start-Transcript -Path (Join-Path $logRoot ('{0:yyyyMMdd-HHmmss}-upgrade-user-{1}.log' -f (Get-Date), $PID)) | Out-Null
try {
    $null = Initialize-AtlasRegistryIdentityContext -CurrentToken -ExpectedUserSid $actualSid
    # Each Tweaks/<category> install step already applied the installing user's HKCU
    # entries, protected policy roots included. This pass is for other accounts
    # migrating at their next logon, under their own token, for every category in the
    # manifest Invoke-AtlasTweakCategory reads.
    if (-not $ExpectedUserSid) {
        $manifest = Get-AtlasTweakManifest -Path (Join-Path $context.AtlasModulesPath 'Scripts\Tweaks\tweaks.manifest.psd1')
        foreach ($category in @($manifest['Categories'] | ForEach-Object { [string]$_['Name'] })) {
            Invoke-AtlasTweakCategory -Name $category -RegistryScope CurrentUser -RegistryOnly -Context $context
        }
    }
    # As in Initialize-NewUser: a choice whose user part fails stays recorded and shows
    # in the health check, without failing the upgrade after its machine work.
    try { Invoke-AtlasToggleUserReapply }
    catch { Write-Warning "Some recorded choices were not applied for this user: $($_.Exception.Message)" }
    # New-Item -Force would recreate an existing key empty, losing Initialize-NewUser's markers.
    if (-not (Test-Path -LiteralPath $markerPath)) { $null = New-Item -Path $markerPath -Force }
    New-ItemProperty -LiteralPath $markerPath -Name $markerName -Value $stamp -PropertyType String -Force | Out-Null
}
finally { Stop-Transcript | Out-Null }
