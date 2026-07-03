# Companion of create-shortcuts.psd1 (was Configuration\tweaks\misc\create-shortcuts.yml).
$ErrorActionPreference = 'Stop'
& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Internal\New-AtlasShortcutSet.ps1')
