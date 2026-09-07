# Companion of add-sharing-settings-shortcut.psd1: creates the 'Sharing Settings'
# shortcut in the Atlas File Sharing folder.
$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Modules\Atlas.Shortcuts\Atlas.Shortcuts.psd1') -ErrorAction Stop

$destination = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasDesktop\3. General Configuration\File Sharing\Sharing Settings.lnk'
$controlPanel = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'control.exe'
New-AtlasShortcut -Source $controlPanel -Destination $destination -Arguments '/name Microsoft.NetworkAndSharingCenter /page Advanced'
