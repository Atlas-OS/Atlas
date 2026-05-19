#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Show Lock Screen (default)
# Restores the Windows lock screen to its default (visible) state.
# Removes NoLockScreen and NoChangingLockScreen so Settings are no longer
# greyed out / "managed by your organization".
# ============================================================================

param(
    [switch]$Silent
)

$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Silent) { $argList += ' -Silent' }
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -Wait
    }
    catch {
        Write-Host '[!!] Administrator privileges are required.' -ForegroundColor Red
        if (-not $Silent) { Read-Host 'Press Enter to exit' }
        exit 1
    }
    exit 0
}

$settingName = 'LockScreen'
$stateValue = 1
$scriptPath = $PSCommandPath

try {
    $atlasKey = "HKLM:\SOFTWARE\AtlasOS\Services\$settingName"
    if (-not (Test-Path $atlasKey)) { New-Item -Path $atlasKey -Force | Out-Null }
    Set-ItemProperty -Path $atlasKey -Name 'state' -Value $stateValue -Type DWord  -Force
    Set-ItemProperty -Path $atlasKey -Name 'path'  -Value $scriptPath -Type String -Force

    $policyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
    Remove-ItemProperty -Path $policyKey -Name 'NoLockScreen'         -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $policyKey -Name 'NoChangingLockScreen' -ErrorAction SilentlyContinue

    if (-not $Silent) {
        Write-Host '[OK] Lock screen restored.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
}
catch {
    Write-Host "[!!] Failed to restore lock screen: $_" -ForegroundColor Red
    exit 1
}
