<#
.SYNOPSIS
  Unattended Windhawk provisioning for a customized Windows 11 image (Atlas-like).
  Silently installs the Windhawk engine and applies a fully-transparent Windows 11
  taskbar via the "Windows 11 Taskbar Styler" mod. Safe to run during image
  deployment or on first system boot (e.g. from SetupComplete.cmd / an unattend
  FirstLogonCommands / a one-shot startup Scheduled Task).

.NOTES
  This uses the headless Windhawk engine (windhawk-cli), the scriptable, service-based
  form of Windhawk. It installs the Windhawk engine itself (no GUI / no compiler) and
  cooperates with the official Windhawk GUI if you install it later.
  To instead use the OFFICIAL Windhawk GUI tool: install it silently
  (windhawk_setup.exe /VERYSILENT /NORESTART) and replace the `whcli` calls below with
  `windhawkctl` (Windhawk 2.0+) equivalents - install-mod / set-mod-settings.
#>

[CmdletBinding()]
param(
    [string]$InstallerUrl,
    [switch]$RegisterFirstBootTask
)

$ErrorActionPreference = 'Stop'

function Assert-Admin {
    $wp = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Requesting elevation..." -ForegroundColor Yellow
        $psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
        Start-Process $psExe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    }
}

function Wait-ForWhcli {
    param($Whcli, $Root, $TimeoutSec = 120)
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (Test-Path $Whcli) {
            try { & $Whcli status --root $Root | Out-Null; return $true } catch { }
        }
        Start-Sleep -Seconds 3
    }
    throw "windhawk-cli did not become ready within $TimeoutSec seconds."
}

Assert-Admin

$root = "C:\Program Files\WindhawkCLI"
$whcli = "$root\whcli.exe"
$modId = 'windows-11-taskbar-styler'

# --- 1. Silently install the Windhawk engine (download + unattended install) ---
if (-not (Test-Path $whcli)) {
    # Prefer a pre-baked installer shipped next to this script (works fully offline,
    # e.g. in a baked image during first boot). Fall back to downloading if absent.
    $localInstaller = Join-Path $PSScriptRoot "windhawk-cli-installer.exe"
    if (Test-Path $localInstaller) {
        Write-Host "Using pre-baked Windhawk installer: $localInstaller" -ForegroundColor Cyan
        $installer = $localInstaller
    } else {
        if (-not $InstallerUrl) {
            $api = "https://api.github.com/repos/hansonxyz/windhawk-cli/releases/latest"
            $rel = Invoke-RestMethod -Uri $api -Headers @{ Accept = "application/vnd.github+json"; 'User-Agent' = 'EBOS-Playbook' }
            $asset = $rel.assets | Where-Object { $_.name -like '*installer.exe' } | Select-Object -First 1
            if (-not $asset) { throw "Could not find a windhawk-cli installer asset in the latest release." }
            $InstallerUrl = $asset.browser_download_url
        }

        $installer = Join-Path $env:TEMP "windhawk-cli-installer.exe"
        Write-Host "Downloading Windhawk engine: $InstallerUrl" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $installer -UseBasicParsing
    }

    Write-Host "Installing Windhawk engine silently..." -ForegroundColor Cyan
    Start-Process -FilePath $installer -ArgumentList '--silent', '--auto-updates', '--add-defender-exclusion' -Wait
    # Only clean up the temp-downloaded copy; keep the pre-baked one for reuse.
    if ($installer -ne $localInstaller) { Remove-Item $installer -Force -ErrorAction SilentlyContinue }
} else {
    Write-Host "Windhawk engine already installed." -ForegroundColor Green
}

Wait-ForWhcli -Whcli $whcli -Root $root

# --- 2. Install the Taskbar Styler mod (precompiled, no compiler needed) ---
Write-Host "Installing mod: $modId" -ForegroundColor Cyan
& $whcli install $modId --root $root

# --- 3. Apply full-transparency settings ---
# These style overrides make the taskbar background fully transparent.
$settings = [ordered]@{
    'theme'                     = ''
    'controlStyles[0].target'  = 'Taskbar.TaskbarFrame > Grid > Taskbar.TaskbarBackground > Grid > Rectangle'
    'controlStyles[0].styles[0]' = 'Fill=Transparent'
    'controlStyles[1].target'  = 'Taskbar.TaskbarBackground > Grid > Rectangle'
    'controlStyles[1].styles[0]' = 'Fill=Transparent'
    'controlStyles[2].target'  = 'Rectangle'
    'controlStyles[2].styles[0]' = 'Fill=Transparent'
}

Write-Host "Applying full-transparency settings..." -ForegroundColor Cyan
foreach ($key in $settings.Keys) {
    $value = $settings[$key]
    if ([string]::IsNullOrEmpty($value)) { $value = '""' }
    & $whcli set-setting $modId $key $value --root $root
}

# --- 4. Make the change live immediately (engine reloads, but restart explorer to be safe) ---
& $whcli restart --root $root
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "Done. The taskbar will be fully transparent on every boot." -ForegroundColor Green

# --- Optional: register this script as a one-shot first-boot task ---
if ($RegisterFirstBootTask) {
    $taskName = "WindhawkTransparentTaskbar"
    $taskPsExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
    $action = New-ScheduledTaskAction -Execute $taskPsExe -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Force | Out-Null
    Write-Host "Registered one-shot first-boot task: $taskName" -ForegroundColor Green
}
