#Requires -RunAsAdministrator

[CmdletBinding()]
param([switch]$Silent)

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
    if ([bool]$binding.Enabled) {
        Disable-NetAdapterBinding -Name ([string]$binding.Name) `
            -ComponentID ([string]$binding.ComponentID) -Confirm:$false `
            -ErrorAction Stop | Out-Null
    }
}
if (@(Get-NetAdapterBinding -Name '*' -ComponentID $components -ErrorAction Stop |
        Where-Object { [bool]$_.Enabled }).Count -ne 0) {
    throw 'File Sharing disable left a managed adapter binding enabled.'
}

$interfacesPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces'
foreach ($interface in @(Get-ChildItem -LiteralPath $interfacesPath -ErrorAction Stop |
            Where-Object { $_.GetValueNames() -contains 'NetbiosOptions' })) {
    Set-ItemProperty -LiteralPath $interface.PSPath -Name 'NetbiosOptions' `
        -Value 2 -Type DWord -Force -ErrorAction Stop
    $key = Get-Item -LiteralPath $interface.PSPath -ErrorAction Stop
    try {
        if ($key.GetValueKind('NetbiosOptions') -ne
            [Microsoft.Win32.RegistryValueKind]::DWord -or
            [int]$key.GetValue('NetbiosOptions') -ne 2) {
            throw "NetBIOS interface '$($interface.PSChildName)' did not retain disabled mode."
        }
    }
    finally {
        $key.Close()
    }
}
Set-AtlasServiceStartup -Name 'NetBT' -StartupType 4

foreach ($networkProfile in @(Get-NetConnectionProfile -ErrorAction Stop)) {
    if ([string]$networkProfile.NetworkCategory -cne 'Public') {
        Set-NetConnectionProfile -InputObject $networkProfile -NetworkCategory Public `
            -ErrorAction Stop
    }
}
if (@(Get-NetConnectionProfile -ErrorAction Stop | Where-Object {
            [string]$_.NetworkCategory -cne 'Public'
        }).Count -ne 0) {
    throw 'File Sharing disable left a network profile outside the Public category.'
}

function Get-AtlasFileSharingFirewallRule {
    @(Get-NetFirewallRule -ErrorAction Stop | Where-Object {
            ($_.Group -in @('@FirewallAPI.dll,-28502', '@FirewallAPI.dll,-32752') -or
                $_.DisplayGroup -in @('File and Printer Sharing', 'Network Discovery')) -and
            $_.Profile -like '*Private*'
        })
}

$rules = @(Get-AtlasFileSharingFirewallRule)
if ($rules.Count -ne 0) {
    $rules | Disable-NetFirewallRule -ErrorAction Stop | Out-Null
}
foreach ($rule in @(Get-AtlasFileSharingFirewallRule)) {
    if ([string]$rule.Enabled -notin @('False', '0')) {
        throw "Firewall rule '$($rule.Name)' did not retain its disabled state."
    }
}

$sharingKeys = @(
    'HKLM:\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\Sharing'
    'HKLM:\SOFTWARE\Classes\Directory\Background\shellex\ContextMenuHandlers\Sharing'
    'HKLM:\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\Sharing'
    'HKLM:\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\Sharing'
    'HKLM:\SOFTWARE\Classes\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'
    'HKLM:\SOFTWARE\Classes\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing'
)
foreach ($key in $sharingKeys) {
    Remove-AtlasRegistryKey -Path $key
    if (Test-Path -LiteralPath $key -ErrorAction Stop) {
        throw "File Sharing disable left the context-menu key '$key'."
    }
}

if (-not $Silent) {
    Write-Host "`nCompleted! " -ForegroundColor Green -NoNewLine
    Write-Host "You'll need to restart to apply the changes." -ForegroundColor Yellow
}
