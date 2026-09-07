# Services phase.
# Backs up the default Windows services, then applies the feature defaults that users
# can later change from AtlasDesktop: File Sharing off, Location off and Indexing
# minimal. Each default is the machine part of the corresponding toggle, applied and
# recorded through the toggle engine so the install and the launcher share one
# implementation and upgrade replay sees the same record a user's choice would leave.
# The committed install plan admits this phase only for fresh modes; it runs as
# TrustedInstaller. Generic Windows service and driver startup values stay at their OS
# defaults; optional product behavior is configured through documented policy or
# feature-specific interfaces.

Assert-AtlasPrivilege -TrustedInstaller

$scriptsRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$atlasModulesRoot = Split-Path -Path $scriptsRoot -Parent
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Services\Atlas.Services.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force -ErrorAction Stop

# Back up default Windows services & drivers (kept if a backup already exists)
$backupPath = Join-Path -Path $atlasModulesRoot -ChildPath 'Other\winServices.reg'
Export-AtlasServicesBackup -FilePath $backupPath

foreach ($default in @(
        @{ Name = 'FileSharing'; State = 'Disable' }
        @{ Name = 'Location'; State = 'Disable' }
        @{ Name = 'Indexing'; State = 'Minimal' }
    )) {
    Invoke-AtlasToggleMachineState -Name $default.Name -State $default.State

    $expected = (Get-AtlasToggleDefinition -Name $default.Name).States[$default.State]['StateValue']
    $recorded = Get-AtlasToggleState -Name $default.Name
    if ($null -eq $recorded -or $null -eq $recorded.State -or [int]$recorded.State -ne [int]$expected) {
        throw "Services phase toggle '$($default.Name)' did not record state '$($default.State)'."
    }
}
