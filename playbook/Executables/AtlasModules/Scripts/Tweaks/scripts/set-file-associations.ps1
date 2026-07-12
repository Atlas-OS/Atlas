[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedUserSid
)

$ErrorActionPreference = 'Stop'

$windowsRoot = [Environment]::GetFolderPath('Windows')
$implementation = Join-Path -Path $windowsRoot -ChildPath 'AtlasModules\Scripts\Internal\Set-FileAssociations.ps1'

Write-Warning 'Protected browser defaults remain user-controlled. Use Windows Default Apps Settings or documented managed-device/first-sign-in provisioning.'
& $implementation -AssociationProfile 'Base' -ExpectedUserSid $ExpectedUserSid
