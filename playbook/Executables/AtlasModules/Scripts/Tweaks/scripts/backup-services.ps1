# Companion of backup-services.psd1.
$ErrorActionPreference = 'Stop'

Import-AtlasModule -Name Atlas.Services
Export-AtlasServicesBackup -FilePath (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Other\atlasServices.reg')
