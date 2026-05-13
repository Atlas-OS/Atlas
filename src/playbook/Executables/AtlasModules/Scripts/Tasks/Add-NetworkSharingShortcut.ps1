$ErrorActionPreference = 'Stop'

$initScript = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\initPowerShell.ps1'
if (-not (Test-Path -LiteralPath $initScript -PathType Leaf)) {
    throw "Atlas PowerShell initialization script '$initScript' is missing."
}

. $initScript

$destination = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasDesktop\3. General Configuration\File Sharing\Sharing Settings.lnk'
New-Shortcut -Source 'control.exe' -Destination $destination -Arguments '/name Microsoft.NetworkAndSharingCenter /page Advanced'
