# Creates the 'Sharing Settings' shortcut in the Atlas File Sharing folder via the
# deployed task script.
$ErrorActionPreference = 'Stop'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Tasks\Add-NetworkSharingShortcut.ps1')
