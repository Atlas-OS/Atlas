# Companion of disable-service-host-split.psd1: the logic lives in AtlasModules\Scripts\Tasks
# so it can also be reused outside the tweak engine.
$ErrorActionPreference = 'Stop'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Tasks\Disable-ServiceHostSplit.ps1')
