# Companion of config-oem-information.psd1: the logic lives in
# AtlasModules\Scripts\Install\Tasks\Set-OemInformation.ps1 because the build stamps the
# Atlas version into that file.
$ErrorActionPreference = 'Stop'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Install\Tasks\Set-OemInformation.ps1')
