# Companion of add-sharing-settings-shortcut.psd1: creates the 'Sharing Settings'
# shortcut in the Atlas File Sharing folder.
$ErrorActionPreference = 'Stop'

Import-AtlasModule -Name Atlas.Shortcuts

$destination = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasDesktop\3. General Configuration\File Sharing\Sharing Settings.lnk'
$controlPanel = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'control.exe'
New-AtlasShortcut -Source $controlPanel -Destination $destination -Arguments '/name Microsoft.NetworkAndSharingCenter /page Advanced'
