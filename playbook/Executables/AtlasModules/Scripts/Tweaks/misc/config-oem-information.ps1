# Companion of config-oem-information.psd1: the logic lives in
# AtlasModules\Scripts\Install\Tasks so it can also be reused outside the tweak engine.
$ErrorActionPreference = 'Stop'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Install\Tasks\Set-OemInformation.ps1')
