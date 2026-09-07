# Starts the three supported TrustedInstaller operations through Atlas.Native.cs.
# Requests select a fixed operation; callers cannot supply an executable or command
# line. Native code resolves protected entry points and uses the TrustedInstaller
# token, with no fallback to LSASS, winlogon or a generic SYSTEM process.

function Get-AtlasCurrentTokenEvidence {
    Initialize-AtlasNativeType
    return [Atlas.Native.TrustedInstallerProcess]::GetCurrentTokenEvidence()
}

function Invoke-AtlasTrustedInstallerNativeOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Toggle', 'ResetServices', 'Install')]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 86400000)]
        [int]$TimeoutMilliseconds,

        [string]$Name,
        [string]$State,
        [switch]$Silent,
        [switch]$JustContext,
        [switch]$NoExplorerRestart,
        [switch]$MachineOnly,
        [ValidateSet('ToggleDefaults', 'WindowsBackup', 'AtlasBackup')]
        [string]$RestoreSource,
        [ValidateSet('Capture', 'Run')]
        [string]$InstallPhase,
        [string]$PayloadRoot
    )

    Initialize-AtlasNativeType

    $request = New-Object -TypeName Atlas.Native.TrustedInstallerLaunchRequest
    $request.Operation = $Operation
    $request.AtlasModulesPath = (Get-AtlasContext).AtlasModulesPath
    $request.ToggleName = $Name
    $request.ToggleState = $State
    $request.Silent = [bool]$Silent
    $request.JustContext = [bool]$JustContext
    $request.NoExplorerRestart = [bool]$NoExplorerRestart
    $request.MachineOnly = [bool]$MachineOnly
    $request.RestoreSource = $RestoreSource
    $request.InstallPhase = $InstallPhase
    $request.PayloadRoot = $PayloadRoot
    $request.TimeoutMilliseconds = $TimeoutMilliseconds

    return [Atlas.Native.TrustedInstallerProcess]::LaunchNonInteractive($request)
}
