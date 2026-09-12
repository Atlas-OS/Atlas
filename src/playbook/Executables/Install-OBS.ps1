<#
.SYNOPSIS
  Downloads and silently installs OBS Studio (pinned version) and pins it to the Start menu.
  Designed to be invoked from the Atlas playbook (.\Install-OBS.ps1, exeDir: true).
#>
$ErrorActionPreference = 'Stop'

# Pinned version (change this single value to bump OBS)
$OBSVersion = '32.2.2'

# Ensure TLS 1.2/1.3 is available
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Resolve the pinned OBS Studio release via the GitHub API
$api = "https://api.github.com/repos/obsproject/obs-studio/releases/tags/$OBSVersion"
$release = Invoke-RestMethod -Uri $api -Headers @{ Accept = "application/vnd.github+json"; 'User-Agent' = 'EBOS-Playbook' }

$asset = $release.assets |
    Where-Object { $_.name -like 'OBS-Studio-*-Windows-Installer.exe' } |
    Select-Object -First 1

if (-not $asset) {
    throw "Could not find a Windows OBS Studio installer in release '$OBSVersion'."
}

$installer = Join-Path $env:TEMP "OBS-Studio-Installer.exe"
Write-Output "Downloading $($asset.name) ($($asset.browser_download_url))..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer -UseBasicParsing

Write-Output "Installing OBS Studio $OBSVersion silently..."
# OBS uses an Inno Setup installer; /S = silent, /allusers = machine-wide
Start-Process -FilePath $installer -ArgumentList '/S', '/allusers' -Wait

Remove-Item $installer -Force -ErrorAction SilentlyContinue

# Pin to the Start menu (machine-wide, all users)
$obsExe = Join-Path $env:ProgramFiles "obs-studio\bin\64bit\obs64.exe"
if (Test-Path $obsExe) {
    $shell = New-Object -ComObject WScript.Shell
    $startMenu = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs"
    if (-not (Test-Path $startMenu)) { New-Item -ItemType Directory -Path $startMenu -Force | Out-Null }
    $lnk = $shell.CreateShortcut((Join-Path $startMenu "OBS Studio.lnk"))
    $lnk.TargetPath = $obsExe
    $lnk.WorkingDirectory = Split-Path $obsExe -Parent
    $lnk.Save()
    Write-Output "Pinned OBS Studio to the Start menu (all users)."
} else {
    Write-Warning "OBS executable not found at '$obsExe'; skipping Start menu pin."
}

Write-Output "OBS Studio installed."
