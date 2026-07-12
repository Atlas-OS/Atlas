<#
.SYNOPSIS
    Elevated broker for the closed Atlas TrustedInstaller operation surface.
.DESCRIPTION
    Accepts only typed Atlas identifiers. The native launcher maps them to fixed scripts
    beneath the installed AtlasModules tree and returns the target's exit code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Toggle', 'ResetServices')]
    [string]$Operation,

    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$')]
    [string]$Name,

    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$')]
    [string]$State,

    [switch]$JustContext,
    [switch]$NoExplorerRestart,
    [switch]$MachineOnly,

    [ValidateSet('ToggleDefaults', 'WindowsBackup', 'AtlasBackup')]
    [string]$RestoreSource,

    [ValidateRange(1, 86400)]
    [int]$TimeoutSeconds = 900
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

try {
    $atlasModulesPath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $coreManifest = Join-Path $atlasModulesPath 'Scripts\Modules\Atlas.Core\Atlas.Core.psd1'
    Import-Module -Name $coreManifest -Force -ErrorAction Stop
    Assert-AtlasPrivilege -Administrator

    $parameters = @{
        Operation           = $Operation
        TimeoutMilliseconds = $TimeoutSeconds * 1000
    }
    switch ($Operation) {
        'Toggle' {
            if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($State)) {
                throw 'Toggle requires typed -Name and -State values.'
            }
            if ($PSBoundParameters.ContainsKey('RestoreSource')) {
                throw "Toggle does not accept '-RestoreSource'."
            }

            $togglesManifest = Join-Path $atlasModulesPath `
                'Scripts\Modules\Atlas.Toggles\Atlas.Toggles.psd1'
            Import-Module -Name $togglesManifest -Force -ErrorAction Stop
            $definition = Get-AtlasToggleDefinition -Name $Name
            if (-not $definition.Contains('Elevation') -or
                [string]$definition.Elevation -cne 'TrustedInstaller') {
                throw "Toggle '$Name' is not declared for TrustedInstaller elevation."
            }
            $matchingStates = @($definition.States.Keys | Where-Object { [string]$_ -ceq $State })
            if ($matchingStates.Count -ne 1) {
                throw "Toggle '$Name' does not declare exact state '$State'."
            }

            $parameters.Name = $Name
            $parameters.State = $State
            $parameters.Silent = $true
            $parameters.JustContext = [bool]$JustContext
            $parameters.NoExplorerRestart = [bool]$NoExplorerRestart
            $parameters.MachineOnly = [bool]$MachineOnly
        }
        'ResetServices' {
            if ([string]::IsNullOrWhiteSpace($RestoreSource)) {
                throw 'ResetServices requires a typed -RestoreSource value.'
            }
            foreach ($parameterName in @('Name', 'State', 'JustContext', 'NoExplorerRestart', 'MachineOnly')) {
                if ($PSBoundParameters.ContainsKey($parameterName)) {
                    throw "ResetServices does not accept '-$parameterName'."
                }
            }
            $parameters.RestoreSource = $RestoreSource
        }
    }

    $result = Invoke-AtlasTrustedInstallerNativeOperation @parameters
    $signedExitCode = [BitConverter]::ToInt32(
        [BitConverter]::GetBytes([uint32]$result.ExitCodeUInt32),
        0
    )
    if ($signedExitCode -ne 0) {
        [Console]::Error.WriteLine(
            "TrustedInstaller $Operation child exited with code $($result.ExitCodeUInt32)."
        )
    }
    exit $signedExitCode
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
