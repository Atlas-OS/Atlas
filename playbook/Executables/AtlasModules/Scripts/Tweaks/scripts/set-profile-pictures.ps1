# Companion of set-profile-pictures.psd1 (was Configuration\tweaks\scripts\script-pfp.yml).
$ErrorActionPreference = 'Stop'
& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Internal\Set-ProfilePictures.ps1')
