<#
.SYNOPSIS
    Applies one fixed machine-only toggle default during an Atlas install.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'DefaultAtlasNetwork',
        'AppStoreArchiving',
        'AutomaticUpdates',
        'ExtractContextMenu'
    )]
    [string]$Name
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$supportedNames = @(
    'DefaultAtlasNetwork'
    'AppStoreArchiving'
    'AutomaticUpdates'
    'ExtractContextMenu'
)
if ($supportedNames -cnotcontains $Name) {
    throw "Install machine-toggle name '$Name' must use exact canonical casing."
}

$modulesRoot = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..\Modules'))
foreach ($moduleName in @('Atlas.Core', 'Atlas.Registry', 'Atlas.Toggles')) {
    $manifestPath = Join-Path -Path $modulesRoot `
        -ChildPath "$moduleName\$moduleName.psd1"
    if (-not [IO.File]::Exists($manifestPath)) {
        throw "Required module manifest '$manifestPath' is missing."
    }

    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Assert-AtlasPrivilege -TrustedInstaller
$context = Get-AtlasContext -Refresh
if (-not $context.IsInstallStateBacked) {
    throw 'Install machine-toggle actions require active Atlas install state.'
}

$stateValue = switch ($Name) {
    'DefaultAtlasNetwork' {
        $networkScript = Join-Path -Path $PSScriptRoot -ChildPath 'Set-NetworkDefaults.ps1'
        if (-not [IO.File]::Exists($networkScript)) {
            throw "The network-default helper is missing at '$networkScript'."
        }

        $null = & $networkScript -Mode Atlas
        1
    }
    'AppStoreArchiving' {
        Set-AtlasRegistryValue `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx' `
            -Name 'AllowAutomaticAppArchiving' `
            -Type DWord `
            -Data 0
        0
    }
    'AutomaticUpdates' {
        Set-AtlasRegistryValue `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
            -Name 'AUOptions' `
            -Type DWord `
            -Data 2
        0
    }
    'ExtractContextMenu' {
        $blockedKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
        foreach ($classId in @(
                '{b8cdcb65-b1bf-4b42-9428-1dfdb7ee92af}'
                '{BD472F60-27FA-11cf-B8B4-444553540000}'
                '{EE07CEF5-3441-4CFB-870A-4002C724783A}'
                '{D12E3394-DE4B-4777-93E9-DF0AC88F8584}'
            )) {
            Set-AtlasRegistryValue `
                -Path $blockedKey `
                -Name $classId `
                -Type String `
                -Data ''
        }
        0
    }
}

Set-AtlasToggleState -Name $Name -State $stateValue
