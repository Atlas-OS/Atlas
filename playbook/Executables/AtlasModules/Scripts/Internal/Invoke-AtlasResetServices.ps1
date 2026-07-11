<#
.SYNOPSIS
    Fixed noninteractive implementation for the broker's ResetServices operation.
.DESCRIPTION
    Always applies the unique service-toggle state whose launcher is marked '(default)'.
    WindowsBackup and AtlasBackup then import one fixed Atlas-owned snapshot, preserving
    the established defaults-first recovery order.
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
$togglesManifest = Join-Path -Path $modulesRoot -ChildPath 'Atlas.Toggles\Atlas.Toggles.psd1'
Import-Module -Name $coreManifest -Force -ErrorAction Stop
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
    if (-not (Test-Path -LiteralPath $snapshot -PathType Leaf)) {
        throw "Fixed $RestoreSource service snapshot '$snapshot' is missing."
    }
}

# Enter the exact module object loaded from the fixed manifest. The private function is
# parameterless and owns the complete service-definition and state allowlist.
& $togglesModule { Invoke-AtlasServiceDefaultsReset }

if ($snapshot) {
    $regExe = Join-Path -Path $context.WinDir -ChildPath 'System32\reg.exe'
    & $regExe import $snapshot
    if ($LASTEXITCODE -ne 0) {
        throw "reg.exe failed to import the fixed $RestoreSource service snapshot with exit code $LASTEXITCODE."
    }
}

exit 0
