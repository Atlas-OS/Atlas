<#
.SYNOPSIS
    Compatibility entry for Set-IndexConfiguration.cmd: one checked Windows Search
    index operation through Atlas.Search, exiting 1 on any failure.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'Include',
        'Exclude',
        'CleanPolicies',
        'Start',
        'Stop',
        'SetRespectPowerModes',
        'ResetSetupCompleted'
    )]
    [string]$Operation,

    [string]$IndexPath,

    [ValidateSet(0, 1)]
    [int]$SettingValue
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($PSScriptRoot))
$bootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($bootstrap)) { throw "The PowerShell bootstrap is missing at '$bootstrap'." }
. $bootstrap
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') `
    -Force -ErrorAction Stop
Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Search\Atlas.Search.psd1') `
    -Force -ErrorAction Stop

try {
    $parameters = @{ Operation = $Operation }
    if ($PSBoundParameters.ContainsKey('IndexPath')) {
        $parameters['IndexPath'] = $IndexPath
    }
    if ($PSBoundParameters.ContainsKey('SettingValue')) {
        $parameters['SettingValue'] = $SettingValue
    }
    Set-AtlasIndexConfiguration @parameters
}
catch {
    Write-Error -ErrorRecord $_ -ErrorAction Continue
    exit 1
}

exit 0
