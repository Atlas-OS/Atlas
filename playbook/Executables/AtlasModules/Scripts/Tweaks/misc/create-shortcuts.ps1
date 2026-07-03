# Companion of create-shortcuts.psd1.
$ErrorActionPreference = 'Stop'
& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Internal\New-AtlasShortcutSet.ps1')
