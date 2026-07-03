# Companion of backup-services.psd1.
$ErrorActionPreference = 'Stop'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\initPowerShell.ps1')
Import-Module Atlas.Services -Force
Export-AtlasServicesBackup -FilePath (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Other\atlasServices.reg')
