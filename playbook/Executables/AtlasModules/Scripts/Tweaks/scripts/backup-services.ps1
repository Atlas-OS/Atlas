# Companion of backup-services.psd1.
$ErrorActionPreference = 'Stop'

$scriptsRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).ProviderPath
. (Join-Path -Path $scriptsRoot -ChildPath 'Initialize-AtlasPowerShell.ps1')
Import-Module -Name (Join-Path $scriptsRoot 'Modules\Atlas.Services\Atlas.Services.psd1') `
    -Force -ErrorAction Stop
Export-AtlasServicesBackup -FilePath (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Other\atlasServices.reg')
