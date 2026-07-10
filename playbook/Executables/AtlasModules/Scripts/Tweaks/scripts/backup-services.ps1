# Companion of backup-services.psd1.
$ErrorActionPreference = 'Stop'

$scriptsRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).ProviderPath
$atlasModulesRoot = Split-Path -Parent $scriptsRoot
& (Join-Path -Path $atlasModulesRoot -ChildPath 'initPowerShell.ps1')
Import-Module -Name (Join-Path $scriptsRoot 'Modules\Atlas.Services\Atlas.Services.psd1') `
    -Force -ErrorAction Stop
Export-AtlasServicesBackup -FilePath (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Other\atlasServices.reg')
