<#
.SYNOPSIS
    CLI entry point for every AtlasDesktop toggle launcher.
.DESCRIPTION
    Generated .cmd launchers call this script as:

        "%__APPDIR__%WindowsPowerShell\v1.0\powershell.exe"
            -NoProfile -NoLogo -ExecutionPolicy Bypass -File
            "%AtlasWindowsRoot%\AtlasModules\Scripts\Invoke-Toggle.ps1"
            -Name <SettingName> [-State <State>] -LauncherPath "%~f0"
            [<canonical launcher flags>]

    Remaining arguments carry the launcher flag surface: /silent (and /quiet),
    /justcontext and /noAction, with either / or - prefixes, case-insensitive.
.NOTES
    Exit codes: 0 = success, 1 = failure.
#>
# PositionalBinding is disabled so bare launcher flags (e.g. a menu launcher invoked as
# '... -Name BootLogo -LauncherPath "..." /silent') fall through to $Rest instead of
# binding positionally to -State.
[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Name,

    [string]$State,

    [string]$LauncherPath,

    [switch]$MachineOnly,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Internal', 'Initialize-PowerShellTrust.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

Set-StrictMode -Version 3.0

# Normalize canonical flags supplied by a generated launcher or a direct caller.
$silent = $false
$justContext = $false
$noExplorerRestart = $false
foreach ($token in @($Rest)) {
    if ([string]::IsNullOrWhiteSpace($token)) {
        continue
    }

    switch ($token.Trim().TrimStart('/', '-').ToLowerInvariant()) {
        'silent' { $silent = $true }
        'quiet' { $silent = $true }
        'justcontext' { $justContext = $true }
        'noaction' { $noExplorerRestart = $true }
        default {
            # Generated launchers reject unknown tokens before this boundary. Keep
            # direct invocation backward-compatible by ignoring unrelated extras.
        }
    }
}

try {
    # Keep command auto-loading rooted in this payload, then import the toggle engine by
    # its exact adjacent manifest so inherited per-user modules cannot shadow it.
    $initScript = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'initPowerShell.ps1'
    if (Test-Path -LiteralPath $initScript -PathType Leaf) {
        & $initScript
    }

    $localModules = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
    $toggleManifest = Join-Path -Path $localModules -ChildPath 'Atlas.Toggles\Atlas.Toggles.psd1'
    Import-Module -Name $toggleManifest -Force -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw 'Invoke-Toggle.ps1 requires -Name <SettingName>.'
    }

    $invokeParams = @{
        Name              = $Name
        Silent            = $silent
        JustContext       = $justContext
        NoExplorerRestart = $noExplorerRestart
        MachineOnly       = [bool]$MachineOnly
    }
    if ($State) {
        $invokeParams['State'] = $State
    }
    if ($LauncherPath) {
        $invokeParams['LauncherPath'] = $LauncherPath
    }

    Invoke-AtlasToggle @invokeParams
    exit 0
}
catch {
    $exitCode = 1
    $adminChildExitKey = 'Atlas.Toggle.AdminChildExitCode'
    if ($null -ne $_.Exception.Data -and $_.Exception.Data.Contains($adminChildExitKey)) {
        try {
            $candidateExitCode = [int]$_.Exception.Data[$adminChildExitKey]
            if ($candidateExitCode -ne 0) {
                $exitCode = $candidateExitCode
            }
        }
        catch {
            $exitCode = 1
        }
    }

    # Silent launches have no interactive window, so the failure must reach the
    # captured process output (and the shared install log when available) for the
    # caller's transcript; the nonzero exit code alone carries no message.
    $failureMessage = "Applying toggle '$Name' failed: $($_.Exception.Message)"
    $failureLogged = $false
    try {
        if (Get-Command -Name Write-AtlasLog -ErrorAction SilentlyContinue) {
            Write-AtlasLog -Level Error -Message $failureMessage -ErrorRecord $_
            $failureLogged = $true
        }
    }
    catch {
        $failureLogged = $false
    }
    if (-not $failureLogged) {
        Write-Host $failureMessage -ForegroundColor Red
    }

    if (-not $silent) {
        Write-Host 'Something went wrong while applying this setting:' -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $null = Read-Host 'Press Enter to exit'
    }
    exit $exitCode
}
