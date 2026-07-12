<#
.SYNOPSIS
    Protected entry point for the few install-time tweaks outside category phases.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'qol/set-hidden-settings-pages',
        'misc/config-oem-information',
        'misc/enable-notifications',
        'scripts/set-power-settings'
    )]
    [string]$Slug
)

$trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Internal', 'Initialize-PowerShellTrust.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$atlasModulesRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, '..'))
$initScript = [IO.Path]::Combine($atlasModulesRoot, 'initPowerShell.ps1')
if (-not [IO.File]::Exists($initScript)) {
    throw "The Atlas PowerShell initializer is missing at '$initScript'."
}
& $initScript

$tweakManifest = [IO.Path]::Combine(
    $PSScriptRoot,
    'Modules',
    'Atlas.Tweaks',
    'Atlas.Tweaks.psd1'
)
if (-not [IO.File]::Exists($tweakManifest)) {
    throw "The Atlas.Tweaks manifest is missing at '$tweakManifest'."
}
Import-Module -Name $tweakManifest -Force -ErrorAction Stop

$relativeTweakPath = $Slug.Replace('/', [IO.Path]::DirectorySeparatorChar) + '.psd1'
$tweakPath = [IO.Path]::Combine($PSScriptRoot, 'Tweaks', $relativeTweakPath)
if (-not [IO.File]::Exists($tweakPath)) {
    throw "The install-time Atlas tweak is missing at '$tweakPath'."
}

$null = Invoke-AtlasTweak -Path $tweakPath
