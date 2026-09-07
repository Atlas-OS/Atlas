# Companion of debloat-send-to.psd1; runs as the exact install-state user.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedUserSid
)

$ErrorActionPreference = 'Stop'

$windowsRoot = [Environment]::GetFolderPath('Windows')
Import-Module -Name (Join-Path -Path $windowsRoot -ChildPath 'AtlasModules\Scripts\Modules\Atlas.Shell\Atlas.Shell.psd1') -ErrorAction Stop

Set-AtlasSendToContextMenu -DebloatDefaults -ExpectedUserSid $ExpectedUserSid
