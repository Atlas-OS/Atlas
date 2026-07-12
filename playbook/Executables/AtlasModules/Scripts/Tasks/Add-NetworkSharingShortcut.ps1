$ErrorActionPreference = 'Stop'

$initScript = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\initPowerShell.ps1'
if (-not (Test-Path -LiteralPath $initScript -PathType Leaf)) {
    throw "Atlas PowerShell initialization script '$initScript' is missing."
}

. $initScript

$destination = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasDesktop\3. General Configuration\File Sharing\Sharing Settings.lnk'
$controlPanel = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'control.exe'
New-AtlasShortcut -Source $controlPanel -Destination $destination -Arguments '/name Microsoft.NetworkAndSharingCenter /page Advanced'
