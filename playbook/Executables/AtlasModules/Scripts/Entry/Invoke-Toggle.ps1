<#
.SYNOPSIS
    CLI entry point for every AtlasDesktop toggle launcher.
.DESCRIPTION
    Every generated AtlasDesktop and Toolbox launcher is a two-line stub that calls the
    shared body Invoke-AtlasToggleLauncher.cmd beside this script, which anchors to the
    protected command host, sanitizes the environment, validates the flag grammar and
    then runs:

        powershell.exe -NoProfile -NoLogo -ExecutionPolicy Bypass -File
            "%AtlasWindowsRoot%\AtlasModules\Scripts\Entry\Invoke-Toggle.ps1"
            -Name <SettingName> [-State <State>] -LauncherPath "<stub path>"
            [<canonical launcher flags>]

    Remaining arguments carry the launcher flag surface: /silent (and /quiet),
    /justcontext and /noAction, with either / or - prefixes, case-insensitive.

    An interactive run presents itself through the Atlas.Core console vocabulary
    (docs/console-presentation.md) and owns the single failure block; a silent run keeps
    the full diagnostic log echo its caller captures.
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

$scriptsRoot = [IO.Path]::GetDirectoryName($PSScriptRoot)
$trustBootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
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

$title = if ($LauncherPath) { [IO.Path]::GetFileNameWithoutExtension($LauncherPath) } else { $Name }

try {
    # The bootstrap above rooted command auto-loading in this payload; import the core
    # presentation and the toggle engine by their exact manifests so inherited per-user
    # modules cannot shadow them. Core first, so the engine's nested import shares the
    # instance whose console style is set here.
    $localModules = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
    $coreManifest = Join-Path -Path $localModules -ChildPath 'Atlas.Core\Atlas.Core.psd1'
    $toggleManifest = Join-Path -Path $localModules -ChildPath 'Atlas.Toggles\Atlas.Toggles.psd1'
    Import-Module -Name $coreManifest -ErrorAction Stop
    Import-Module -Name $toggleManifest -Force -ErrorAction Stop

    if (-not $silent) {
        Set-AtlasLogConsoleStyle -Style Interactive
    }

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
    # caller's transcript; the nonzero exit code alone carries no message. An
    # interactive run shows the reason once, in its failure block.
    $reason = [string]$_.Exception.Message
    $failureMessage = "Applying toggle '$Name' failed: $reason"
    $failureLogged = $false
    $detailsPath = $null
    try {
        if (Get-Command -Name Write-AtlasLog -ErrorAction SilentlyContinue) {
            Write-AtlasLog -Level Error -Message $failureMessage -ErrorRecord $_ -NoConsole:(-not $silent)
            $failureLogged = $true
        }
        if (Get-Command -Name Get-AtlasInstallLogPath -ErrorAction SilentlyContinue) {
            $detailsPath = Get-AtlasInstallLogPath
        }
    }
    catch {
        $failureLogged = $false
    }
    if (-not $failureLogged) {
        Write-Host $failureMessage -ForegroundColor Red
    }

    if (-not $silent) {
        if (Get-Command -Name Write-AtlasNotApplied -ErrorAction SilentlyContinue) {
            Write-AtlasNotApplied -Title $title -Reason $reason -DetailsPath $detailsPath
            Wait-AtlasExit
        }
        else {
            Write-Host "Not applied: $title." -ForegroundColor Red
            Write-Host "Error: $reason" -ForegroundColor Red
            $null = Read-Host 'Press Enter to exit'
        }
    }
    exit $exitCode
}
