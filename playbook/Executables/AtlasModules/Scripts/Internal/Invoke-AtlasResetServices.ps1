<#
.SYNOPSIS
    Fixed noninteractive implementation for the broker's ResetServices operation.
.DESCRIPTION
    Always applies the unique service-toggle state whose launcher is marked '(default)'.
    WindowsBackup and AtlasBackup then restore typed Start values from one strictly
    validated Atlas-owned snapshot, preserving the established defaults-first order.
    No caller-selected script, executable, registry file, or argument vector is accepted.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('ToggleDefaults', 'WindowsBackup', 'AtlasBackup')]
    [string]$RestoreSource
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$validRestoreSources = @('ToggleDefaults', 'WindowsBackup', 'AtlasBackup')
if ($validRestoreSources -cnotcontains $RestoreSource) {
    throw 'RestoreSource must use exact canonical casing.'
}

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
$coreManifest = Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1'
$servicesManifest = Join-Path -Path $modulesRoot -ChildPath 'Atlas.Services\Atlas.Services.psd1'
$togglesManifest = Join-Path -Path $modulesRoot -ChildPath 'Atlas.Toggles\Atlas.Toggles.psd1'
Import-Module -Name $coreManifest -Force -ErrorAction Stop
$servicesModules = @(Import-Module -Name $servicesManifest -Force -PassThru -ErrorAction Stop)
if ($servicesModules.Count -ne 1) {
    throw "The fixed Atlas.Services manifest loaded $($servicesModules.Count) module objects; expected exactly one."
}
$servicesModule = $servicesModules[0]
$expectedServicesModulePath = [IO.Path]::GetFullPath(
    (Join-Path -Path (Split-Path -Parent $servicesManifest) -ChildPath 'Atlas.Services.psm1')
)
if ([string]::IsNullOrWhiteSpace([string]$servicesModule.Path) -or
    -not [string]::Equals(
        [IO.Path]::GetFullPath([string]$servicesModule.Path),
        $expectedServicesModulePath,
        [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "The loaded Atlas.Services module does not match the fixed manifest '$servicesManifest'."
}
$togglesModules = @(Import-Module -Name $togglesManifest -Force -PassThru -ErrorAction Stop)
if ($togglesModules.Count -ne 1) {
    throw "The fixed Atlas.Toggles manifest loaded $($togglesModules.Count) module objects; expected exactly one."
}
$togglesModule = $togglesModules[0]
$expectedTogglesModulePath = [IO.Path]::GetFullPath(
    (Join-Path -Path (Split-Path -Parent $togglesManifest) -ChildPath 'Atlas.Toggles.psm1')
)
if ([string]::IsNullOrWhiteSpace([string]$togglesModule.Path) -or
    -not [string]::Equals(
        [IO.Path]::GetFullPath([string]$togglesModule.Path),
        $expectedTogglesModulePath,
        [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "The loaded Atlas.Toggles module does not match the fixed manifest '$togglesManifest'."
}
Assert-AtlasPrivilege -TrustedInstaller

$context = Get-AtlasContext
$snapshot = $null
if ($RestoreSource -cne 'ToggleDefaults') {
    $fileName = if ($RestoreSource -ceq 'WindowsBackup') { 'winServices.reg' } else { 'atlasServices.reg' }
    $snapshot = Join-Path -Path $context.AtlasModulesPath -ChildPath "Other\$fileName"
}

# Enter the exact module object loaded from the fixed manifest. The private function is
# parameterless and owns the complete service-definition and state allowlist.
& $togglesModule { Invoke-AtlasServiceDefaultsReset }

if ($snapshot) {
    [void](Restore-AtlasServicesBackup -FilePath $snapshot)
}

exit 0
