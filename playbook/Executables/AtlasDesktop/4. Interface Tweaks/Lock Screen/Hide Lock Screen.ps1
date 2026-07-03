#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Hide Lock Screen
# Disables the Windows lock screen via registry policy.
# Sets NoLockScreen and NoChangingLockScreen so Settings stay accessible
# (prevents the "managed by your organization" greyed-out state).
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
    } catch {
        Write-Host '[!!] Administrator privileges are required.' -ForegroundColor Red
        if (-not $Silent) { Read-Host 'Press Enter to exit' }
        exit 1
    }
    exit 0
}

$settingName = 'LockScreen'
$stateValue  = 0
$scriptPath  = $PSCommandPath

try {
    $atlasKey = "HKLM:\SOFTWARE\AtlasOS\Services\$settingName"
    if (-not (Test-Path $atlasKey)) { New-Item -Path $atlasKey -Force | Out-Null }
    Set-ItemProperty -Path $atlasKey -Name 'state' -Value $stateValue -Type DWord  -Force
    Set-ItemProperty -Path $atlasKey -Name 'path'  -Value $scriptPath -Type String -Force

    $policyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
    if (-not (Test-Path $policyKey)) { New-Item -Path $policyKey -Force | Out-Null }
    Set-ItemProperty -Path $policyKey -Name 'NoLockScreen'         -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $policyKey -Name 'NoChangingLockScreen' -Value 1 -Type DWord -Force

    if (-not $Silent) {
        Write-Host '[OK] Lock screen hidden.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to hide lock screen: $_" -ForegroundColor Red
    exit 1
}