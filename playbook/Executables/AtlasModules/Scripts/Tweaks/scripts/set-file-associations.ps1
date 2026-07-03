# Companion of set-file-associations.psd1.
# The launcher enumerates the loaded user hives itself, so it is TrustedInstaller-safe.
$ErrorActionPreference = 'Stop'
$launcher = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Set-FileAssociationsLauncher.cmd'

# Base associations, unless Edge is being uninstalled.
if (-not (Test-AtlasOption -Name 'uninstall-edge')) {
    & $launcher
}

# Browser-specific associations for the user's chosen browser.
if (Test-AtlasOption -Name 'browser-brave') { & $launcher 'Brave' }
if (Test-AtlasOption -Name 'browser-librewolf') { & $launcher 'LibreWolf' }
if (Test-AtlasOption -Name 'browser-firefox') { & $launcher 'Firefox' }
if (Test-AtlasOption -Name 'browser-chrome') { & $launcher 'Google Chrome' }
