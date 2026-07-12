<#
.SYNOPSIS
    Typed CLI for Atlas TrustedInstaller operations.
.DESCRIPTION
    This CLI deliberately has no arbitrary executable, script, command, or argument-list
    parameters. A parameter-bound invocation prints either one complete elevation outcome
    or a separately versioned CLI validation error. PowerShell parameter-binding errors are
    emitted by PowerShell before the script body runs. Only a Completed operation exits with
    the target's exact 32-bit exit-code pattern; infrastructure failures exit 1.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Toggle', 'ResetServices')]
    [string]$Operation,

    [string]$Name,
    [string]$State,
    [bool]$Silent = $true,
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
    if (@('Toggle', 'ResetServices') -cnotcontains $Operation) {
        throw "TrustedInstaller operation '$Operation' is not canonical."
    }
    $operationParameterAllowlist = @{
        Toggle           = @('Name', 'State', 'Silent', 'JustContext', 'NoExplorerRestart', 'MachineOnly')
        ResetServices = @('RestoreSource')
    }
    $allOperationParameters = @(
        'Name', 'State', 'Silent', 'JustContext', 'NoExplorerRestart', 'MachineOnly', 'RestoreSource'
    )
    foreach ($operationParameter in $allOperationParameters) {
        if ($PSBoundParameters.ContainsKey($operationParameter) -and
            $operationParameter -notin $operationParameterAllowlist[$Operation]) {
            throw "$Operation does not accept the operation input '-$operationParameter'."
        }
    }

    $coreManifest = Join-Path -Path $PSScriptRoot -ChildPath 'Modules\Atlas.Core\Atlas.Core.psd1'
    Import-Module -Name $coreManifest -Force -ErrorAction Stop

    $parameters = @{
        Operation      = $Operation
        TimeoutSeconds = $TimeoutSeconds
    }
    switch ($Operation) {
        'Toggle' {
            $parameters.Name = $Name
            $parameters.State = $State
            $parameters.Silent = $Silent
            $parameters.JustContext = [bool]$JustContext
            $parameters.NoExplorerRestart = [bool]$NoExplorerRestart
            $parameters.MachineOnly = [bool]$MachineOnly
        }
        'ResetServices' {
            $parameters.RestoreSource = $RestoreSource
        }
    }

    $result = Invoke-AtlasTrustedInstaller @parameters
    $result | ConvertTo-Json -Depth 8 -Compress
    if ($result.status -ceq 'Completed') {
        $signedExitCode = [BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]$result.exitCodeUInt32), 0)
        exit $signedExitCode
    }
    exit 1
}
catch {
    [pscustomobject][ordered]@{
        schema = 'AtlasElevationCliError/1'
        code   = 'CallerValidationFailure'
        error  = $_.Exception.Message
    } | ConvertTo-Json -Compress
    exit 1
}
