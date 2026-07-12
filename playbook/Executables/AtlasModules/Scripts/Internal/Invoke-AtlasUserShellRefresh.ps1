<#
.SYNOPSIS
    Refreshes only the current medium user's shell in the current Windows session.
#>
[CmdletBinding(DefaultParameterSetName = 'InstallBound')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'InstallBound')]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedUserSid,

    [Parameter(Mandatory = $true, ParameterSetName = 'CurrentSession')]
    [switch]$CurrentSession,

    [ValidateSet(
        'ShellRefresh',
        'ExplorerRefresh',
        'SearchShellRefresh',
        'StartMenuRefresh',
        'ExplorerAndSettingsRefresh',
        'AppxQuiesce'
    )]
    [string]$Operation = 'ShellRefresh'
)

$trustBootstrap = Join-Path $PSScriptRoot 'Initialize-PowerShellTrust.ps1'
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
[void]$CurrentSession

$failureStage = 'Bootstrap'
trap {
    $exitCode = switch -CaseSensitive ($failureStage) {
        'Identity' { 11 }
        'ProcessStop' { 12 }
        'ExplorerStart' { 13 }
        'ExplorerRecovery' { 14 }
        default { 10 }
    }
    exit $exitCode
}

$modulesRoot = Join-Path $PSScriptRoot '..\Modules'
Import-Module (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
Import-Module (Join-Path $modulesRoot 'Atlas.TasksProcs\Atlas.TasksProcs.psd1') -Force -ErrorAction Stop

$failureStage = 'Identity'
if ((Test-AtlasSystem) -or (Test-AtlasAdmin)) {
    throw 'User-shell refresh requires a non-elevated interactive user token; Administrator, SYSTEM, and TrustedInstaller tokens are never accepted.'
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
try {
    $actualSid = $identity.User.Value
}
finally {
    $identity.Dispose()
}

if ($PSCmdlet.ParameterSetName -ceq 'InstallBound') {
    $canonicalExpectedSid = try {
        (New-Object Security.Principal.SecurityIdentifier($ExpectedUserSid)).Value
    }
    catch {
        throw "Expected user-shell refresh SID '$ExpectedUserSid' is invalid."
    }
    if (-not [string]::Equals($actualSid, $canonicalExpectedSid, [StringComparison]::OrdinalIgnoreCase)) {
        throw "User-shell refresh token SID '$actualSid' does not match '$ExpectedUserSid'."
    }
}

$currentProcess = [Diagnostics.Process]::GetCurrentProcess()
try {
    $sessionId = [int]$currentProcess.SessionId
}
finally {
    $currentProcess.Dispose()
}
if ($sessionId -lt 1) {
    throw 'User-shell refresh requires a nonzero interactive Windows session.'
}

$processNames = switch -CaseSensitive ($Operation) {
    'ShellRefresh' { @('ShellExperienceHost', 'explorer') }
    'ExplorerRefresh' { @('explorer') }
    'SearchShellRefresh' { @('SearchHost', 'SearchApp', 'explorer') }
    'StartMenuRefresh' { @('StartMenuExperienceHost') }
    'ExplorerAndSettingsRefresh' { @('SettingsApp', 'explorer') }
    'AppxQuiesce' { @('msteams*', 'ms-teams*', 'SearchHost*', 'SearchApp*') }
    default { throw "Unsupported user-session process operation '$Operation'." }
}

# Even if the same account has another disconnected or RDP logon, only this
# helper's Windows session is refreshed.
$failureStage = 'ProcessStop'
Stop-AtlasProcess -Name $processNames -SessionId $sessionId `
    -StopOnError -WaitTimeoutMilliseconds 5000

if ($Operation -in @(
        'ShellRefresh',
        'ExplorerRefresh',
        'SearchShellRefresh',
        'ExplorerAndSettingsRefresh'
    )) {
    # This script already runs as the intended non-elevated user, so Explorer is
    # launched directly in that user and session before readiness is checked.
    $failureStage = 'ExplorerStart'
    $explorerPath = Join-Path ([Environment]::GetFolderPath('Windows')) 'explorer.exe'
    Start-Process -FilePath $explorerPath -ErrorAction Stop
    $failureStage = 'ExplorerRecovery'
    $null = Wait-AtlasExplorerShellRecovery -SessionId $sessionId -TimeoutSeconds 15
}
