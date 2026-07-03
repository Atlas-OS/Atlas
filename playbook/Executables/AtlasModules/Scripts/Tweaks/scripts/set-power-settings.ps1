# Companion of set-power-settings.psd1 (was Configuration\tweaks\scripts\script-power.yml).
$ErrorActionPreference = 'Stop'
$desktop = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasDesktop'

# Disable power-saving features (option: disable-power-saving).
if (Test-AtlasOption -Name 'disable-power-saving') {
    & (Join-Path -Path $desktop -ChildPath '3. General Configuration\Power-saving\Disable Power-saving.cmd') /silent
}

# Disable hibernation (option: disable-hibernation) - also makes NTFS accessible outside Windows.
if (Test-AtlasOption -Name 'disable-hibernation') {
    & (Join-Path -Path $desktop -ChildPath '3. General Configuration\Hibernation\Disable Hibernation (default).cmd') /silent
}

# Keep the Balanced power scheme when power saving is retained (was option: '!disable-power-saving').
if (-not (Test-AtlasOption -Name 'disable-power-saving')) {
    & powercfg.exe /setactive '381b4222-f694-41f0-9685-ff5bb260df2e'
}
