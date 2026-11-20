<#
.SYNOPSIS
    Refreshes only the current medium user's shell in the current Windows session.
.DESCRIPTION
    Stops the shell processes the operation names in this process's own Windows session,
    then waits for Windows to restart Explorer, starting it only if Windows doesn't.
    Another session of the same account is left alone.

    The install's shell refresh and tweaks phases start it in the installing user's
    token with -ExpectedUserSid, and Clear-AtlasUserAppxCache.ps1 runs it that way with
    the call operator. The toggle engine and the Install Open-Shell desktop launcher
    start it in the signed-in user's session with -CurrentSession, which refuses an
    elevated, SYSTEM or TrustedInstaller token.
.PARAMETER ExpectedUserSid
    The SID of the user the install recorded; the script stops if its token differs.
.PARAMETER CurrentSession
    Refreshes the shell of whoever runs it, which must be a non-elevated user.
.PARAMETER Operation
    Which processes to stop: ShellRefresh (the default), ExplorerRefresh,
    SearchShellRefresh, StartMenuRefresh, ExplorerAndSettingsRefresh, or AppxQuiesce,
    which stops Teams and Search so their packages can change.
.NOTES
    Exit codes name the stage that failed, as Atlas.Core's RunAsUser.ps1 reads them:
    0   Done.
    10  The bootstrap or a module import failed.
    11  -CurrentSession was given an elevated, SYSTEM or TrustedInstaller token.
    12  A process didn't stop.
    13  Explorer couldn't be started.
    14  Explorer didn't come back.
    15  The token doesn't match ExpectedUserSid.
    16  The process isn't in an interactive Windows session.
    17  The operation isn't supported.
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

$trustBootstrap = Join-Path (Split-Path -Parent $PSScriptRoot) 'Initialize-AtlasPowerShell.ps1'
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
[void]$CurrentSession

function Restore-AtlasUserExplorer {
    param([Parameter(Mandatory = $true)][int]$SessionId)

    # Windows normally restarts its shell itself. A second explorer.exe launch
    # opens a folder window instead, interrupting the installation UI.
    try {
        $null = Wait-AtlasExplorerShellRecovery -SessionId $SessionId -TimeoutSeconds 5
        return
    }
    catch {
        # Recover explicitly only when Windows has not restored the shell.
        Write-Verbose 'Windows has not restored Explorer; starting the shell.'
    }
    $explorerPath = Join-Path ([Environment]::GetFolderPath('Windows')) 'explorer.exe'
    Start-Process -FilePath $explorerPath -WindowStyle Hidden -ErrorAction Stop
    $null = Wait-AtlasExplorerShellRecovery -SessionId $SessionId -TimeoutSeconds 15
}

$failureStage = 'Bootstrap'
trap {
    $exitCode = switch -CaseSensitive ($failureStage) {
        'CurrentSessionIdentity' { 11 }
        'ProcessStop' { 12 }
        'ExplorerStart' { 13 }
        'ExplorerRecovery' { 14 }
        'UserSid' { 15 }
        'WindowsSession' { 16 }
        'Operation' { 17 }
        default { 10 }
    }
    exit $exitCode
}

$modulesRoot = Join-Path $PSScriptRoot '..\Modules'
Import-Module (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
Import-Module (Join-Path $modulesRoot 'Atlas.TasksProcs\Atlas.TasksProcs.psd1') -Force -ErrorAction Stop

$failureStage = 'CurrentSessionIdentity'
if ($PSCmdlet.ParameterSetName -ceq 'CurrentSession' -and
    ((Test-AtlasSystem) -or (Test-AtlasAdmin))) {
    throw 'User-shell refresh requires a non-elevated interactive user token; Administrator, SYSTEM, and TrustedInstaller tokens are never accepted.'
}

$failureStage = 'UserSid'
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

$failureStage = 'WindowsSession'
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

$failureStage = 'Operation'
$processNames = switch -CaseSensitive ($Operation) {
    'ShellRefresh' { @('ShellExperienceHost', 'explorer') }
    'ExplorerRefresh' { @('explorer') }
    'SearchShellRefresh' { @('SearchHost', 'SearchApp', 'explorer') }
    'StartMenuRefresh' { @('StartMenuExperienceHost') }
    'ExplorerAndSettingsRefresh' { @('SystemSettings', 'explorer') }
    'AppxQuiesce' { @('msteams*', 'ms-teams*', 'SearchHost*', 'SearchApp*') }
    default { throw "Unsupported user-session process operation '$Operation'." }
}

# Even if the same account has another disconnected or remote session, only this
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
    $failureStage = 'ExplorerRecovery'
    Restore-AtlasUserExplorer -SessionId $sessionId
}
