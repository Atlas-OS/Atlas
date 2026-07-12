#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch]$Silent,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$StateRoot
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1') `
    -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Services\Atlas.Services.psd1') `
    -Force -ErrorAction Stop

$components = @('ms_msclient', 'ms_server', 'ms_lltdio', 'ms_rspndr')
foreach ($binding in @(Get-NetAdapterBinding -Name '*' -ComponentID $components `
            -ErrorAction Stop)) {
    if (-not [bool]$binding.Enabled) {
        Enable-NetAdapterBinding -Name ([string]$binding.Name) `
            -ComponentID ([string]$binding.ComponentID) -Confirm:$false `
            -ErrorAction Stop | Out-Null
    }
}
if (@(Get-NetAdapterBinding -Name '*' -ComponentID $components -ErrorAction Stop |
        Where-Object { -not [bool]$_.Enabled }).Count -ne 0) {
    throw 'File Sharing enable left a managed adapter binding disabled.'
}

$interfacesPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces'
foreach ($interface in @(Get-ChildItem -LiteralPath $interfacesPath -ErrorAction Stop |
            Where-Object { $_.GetValueNames() -contains 'NetbiosOptions' })) {
    Set-ItemProperty -LiteralPath $interface.PSPath -Name 'NetbiosOptions' `
        -Value 1 -Type DWord -Force -ErrorAction Stop
    $key = Get-Item -LiteralPath $interface.PSPath -ErrorAction Stop
    try {
        if ($key.GetValueKind('NetbiosOptions') -ne
            [Microsoft.Win32.RegistryValueKind]::DWord -or
            [int]$key.GetValue('NetbiosOptions') -ne 1) {
            throw "NetBIOS interface '$($interface.PSChildName)' did not retain enabled mode."
        }
    }
    finally {
        $key.Close()
    }
}
Set-AtlasServiceStartup -Name 'NetBT' -StartupType 1

# Network Discovery owns the rest of the service dependency chain, including SMB.
Invoke-AtlasToggleMachineDependency -Name 'NetworkDiscovery' -State 'Enable' `
    -StateRoot $StateRoot

if (-not $Silent) {
    if ((Read-Host "Would you like to change active network profiles to 'Private'? [Y/N]") `
        -match '^(y|yes)$') {
        foreach ($networkProfile in @(Get-NetConnectionProfile -ErrorAction Stop)) {
            if ([string]$networkProfile.NetworkCategory -cne 'Private') {
                Set-NetConnectionProfile -InputObject $networkProfile -NetworkCategory Private `
                    -ErrorAction Stop
            }
        }

        $rules = @(Get-NetFirewallRule -ErrorAction Stop | Where-Object {
                ($_.Group -in @('@FirewallAPI.dll,-28502', '@FirewallAPI.dll,-32752') -or
                    $_.DisplayGroup -in @('File and Printer Sharing', 'Network Discovery')) -and
                $_.Profile -like '*Private*'
            })
        if ($rules.Count -ne 0) {
            $rules | Enable-NetFirewallRule -ErrorAction Stop | Out-Null
        }
        foreach ($rule in @($rules)) {
            $current = @(Get-NetFirewallRule -Name $rule.Name -ErrorAction Stop)
            if ($current.Count -ne 1 -or [string]$current[0].Enabled -notin @('True', '1')) {
                throw "Firewall rule '$($rule.Name)' did not retain its enabled state."
            }
        }

        Set-AtlasRegistryValue `
            -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private' `
            -Name 'AutoSetup' -Type DWord -Data 1
    }

    if ((Read-Host "Would you like to restore the 'Give access to' context menu? [Y/N]") `
        -match '^(y|yes)$') {
        foreach ($key in @(
                'Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\Sharing'
                'Registry::HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\Sharing'
                'Registry::HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\Sharing'
                'Registry::HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\Sharing'
                'Registry::HKEY_CLASSES_ROOT\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'
                'Registry::HKEY_CLASSES_ROOT\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing'
            )) {
            Set-AtlasRegistryValue -Path $key -Name '' -Type String `
                -Data '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}'
        }
    }

    Write-Host "`nCompleted! " -ForegroundColor Green -NoNewLine
    Write-Host "You'll need to restart to apply the changes." -ForegroundColor Yellow
}
