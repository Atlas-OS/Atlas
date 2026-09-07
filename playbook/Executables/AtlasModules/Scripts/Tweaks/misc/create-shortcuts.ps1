# Companion of create-shortcuts.psd1.
$ErrorActionPreference = 'Stop'
& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Operations\New-AtlasShortcutSet.ps1')
