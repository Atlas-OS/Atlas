<#
.SYNOPSIS
    CLI entry point for every AtlasDesktop toggle launcher.
.DESCRIPTION
    Generated .cmd launchers call this script as:

        powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File
            "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1"
            -Name <SettingName> [-State <State>] -LauncherPath "%~f0" %*

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

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

Set-StrictMode -Version 3.0

# Normalize the flags forwarded by the launcher's %*.
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
            # Unknown extra arguments are ignored; launchers forward %* verbatim.
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
    if (-not $silent) {
        Write-Host 'Something went wrong while applying this setting:' -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $null = Read-Host 'Press Enter to exit'
    }
    exit 1
}
