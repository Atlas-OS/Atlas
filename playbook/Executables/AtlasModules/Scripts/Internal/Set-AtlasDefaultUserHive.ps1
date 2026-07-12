<#
.SYNOPSIS
    Reconciles the Atlas default-profile registry hive mount for install/resume.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Loaded', 'Unloaded')]
    [string]$State
)

$trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

. (Join-Path -Path $PSScriptRoot -ChildPath 'Default-UserHive.ps1')

$windowsPath = [Environment]::GetFolderPath('Windows')
$regExePath = Join-Path -Path $windowsPath -ChildPath 'System32\reg.exe'
$profileListPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
$defaultProfileTemplate = (Get-ItemProperty -Path $profileListPath -Name 'Default' `
    -ErrorAction Stop).Default
if ([string]::IsNullOrWhiteSpace([string]$defaultProfileTemplate)) {
    throw "The Windows Default profile path is missing from '$profileListPath'."
}
$defaultProfilePath = [Environment]::ExpandEnvironmentVariables([string]$defaultProfileTemplate)
if (-not [IO.Path]::IsPathRooted($defaultProfilePath)) {
    throw "The Windows Default profile path is not rooted: '$defaultProfilePath'."
}
$hivePath = Join-Path -Path ([IO.Path]::GetFullPath($defaultProfilePath)) -ChildPath 'NTUSER.DAT'

$null = Set-AtlasDefaultUserHiveState -State $State -RegExePath $regExePath -HivePath $hivePath
