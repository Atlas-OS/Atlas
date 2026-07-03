<#
.SYNOPSIS
    CLI entry point for every AtlasDesktop toggle launcher.
.DESCRIPTION
    Generated .cmd launchers call this script as:

        powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File
            "%windir%\AtlasModules\Scripts\invokeToggle.ps1"
            -Name <SettingName> [-State <State>] -LauncherPath "%~f0" %*

    Remaining arguments keep the legacy flag surface working unchanged: /silent (and
    /quiet), /justcontext and /noAction, with either / or - prefixes, case-insensitive.
.NOTES
    Exit codes: 0 = success, 1 = failure.
#>
# PositionalBinding is disabled so bare legacy flags (e.g. a menu launcher invoked as
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

# Normalize legacy flags forwarded by the launcher's %*.
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
            # Unknown extra arguments are ignored for batch parity.
        }
    }
}

try {
    # initPowerShell.ps1 adds the deployed AtlasModules module folder to PSModulePath;
    # also add the folder next to this script so repo checkouts resolve identically.
    $initScript = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'initPowerShell.ps1'
    if (Test-Path -LiteralPath $initScript -PathType Leaf) {
        & $initScript
    }

    $localModules = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
    if (($env:PSModulePath -split ';') -notcontains $localModules) {
        $env:PSModulePath += ";$localModules"
    }

    Import-Module -Name 'Atlas.Toggles' -Force -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw 'invokeToggle.ps1 requires -Name <SettingName>.'
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
