<#
.SYNOPSIS
    Applies only Windows-protected HKCU policy entries to the exact installing user.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('networking', 'performance', 'privacy', 'qol', 'security', 'debloat', 'scripts', 'misc')]
    [string]$Category,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedUserSid,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TransactionId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1, 65536)]
    [string]$OptionsBase64,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$WindowsBuild,

    [switch]$IsUpgrade,

    [switch]$IsArm64
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$scriptsRoot = Split-Path -Path $PSScriptRoot -Parent
$atlasModulesRoot = Split-Path -Path $scriptsRoot -Parent
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Tweaks\Atlas.Tweaks.psd1') -Force -ErrorAction Stop

Assert-AtlasPrivilege -TrustedInstaller
$null = Initialize-AtlasRegistryIdentityContext -InstallingUserPoliciesOnly `
    -InstallingUserSid $ExpectedUserSid -TransactionId $TransactionId

try {
    $optionsJson = [Text.Encoding]::UTF8.GetString(
        [Convert]::FromBase64String($OptionsBase64)
    )
    $decodedOptions = ConvertFrom-Json -InputObject $optionsJson -ErrorAction Stop
    [string[]]$options = @()
    if ($null -ne $decodedOptions) {
        $options = [string[]]$decodedOptions
    }
}
catch {
    throw "The installing-user option snapshot is invalid: $($_.Exception.Message)"
}

$context = [pscustomobject]@{
    WinDir               = [Environment]::GetFolderPath('Windows')
    AtlasModulesPath     = $atlasModulesRoot
    IsArm64              = [bool]$IsArm64
    WindowsBuild         = $WindowsBuild
    IsUpgrade            = [bool]$IsUpgrade
    IsOobe               = $false
    IsInstallStateBacked = $true
    Options              = $options
}
Invoke-AtlasTweakCategory -Name $Category -RegistryScope ProtectedCurrentUser `
    -RegistryOnly -Context $context
