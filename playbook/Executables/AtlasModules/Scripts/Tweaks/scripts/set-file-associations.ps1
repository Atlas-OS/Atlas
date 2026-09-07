[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedUserSid
)

$ErrorActionPreference = 'Stop'

$windowsRoot = [Environment]::GetFolderPath('Windows')
Import-Module -Name (Join-Path -Path $windowsRoot -ChildPath 'AtlasModules\Scripts\Modules\Atlas.Shell\Atlas.Shell.psd1') -ErrorAction Stop

Write-Warning 'Protected browser defaults remain user-controlled. Use Windows Default Apps Settings or documented managed-device/first-sign-in provisioning.'
Set-AtlasFileAssociations -AssociationProfile 'Base' -ExpectedUserSid $ExpectedUserSid
