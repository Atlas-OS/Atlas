<#
.SYNOPSIS
    Generates the AtlasDesktop .cmd launchers from the toggle definitions under
    playbook\Executables\AtlasModules\Toggles.
.DESCRIPTION
    Every toggle state that declares a 'Launcher' (AtlasDesktop-relative path) gets a
    CRLF .cmd launcher that forwards to Invoke-Toggle.ps1. The launcher accepts only
    the supported /silent, /quiet, /justcontext, and /noaction flag grammar, then
    forwards canonical literal flags instead of reparsing an arbitrary command tail.
    Menu definitions declare a single top-level 'Launcher' and omit -State.

    With -Validate, no files are written: the expected launchers are regenerated in
    memory and diffed against the files on disk. Drifted, missing and orphaned launchers
    (Invoke-Toggle-style .cmd files with no matching definition) are reported and the
    script exits 1 on any problem.
.EXAMPLE
    .\New-ToggleLaunchers.ps1            # (re)generate all launchers
    .\New-ToggleLaunchers.ps1 -Validate  # CI drift check
#>
[CmdletBinding()]
param(
    # Repository root; defaults to two levels above this script (tools\dev).
    [string]$RepoRoot,

    [switch]$Validate
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
}

$togglesRoot = Join-Path -Path $RepoRoot -ChildPath 'playbook\Executables\AtlasModules\Toggles'
$desktopRoot = Join-Path -Path $RepoRoot -ChildPath 'playbook\Executables\AtlasDesktop'
# The AtlasToolbox GUI invokes Toolbox\**\*.cmd by hard-coded path; toggles that are also
# surfaced there declare a 'ToolboxLauncher' (Toolbox-relative path) and get a launcher
# generated under this root, exactly like their AtlasDesktop launcher.
$toolboxRoot = Join-Path -Path $RepoRoot -ChildPath 'playbook\Executables\AtlasModules\Toolbox'

if (-not (Test-Path -LiteralPath $togglesRoot -PathType Container)) {
    Write-Error "Toggle definitions root '$togglesRoot' does not exist."
    exit 1
}
if (-not (Test-Path -LiteralPath $desktopRoot -PathType Container)) {
    Write-Error "AtlasDesktop root '$desktopRoot' does not exist."
    exit 1
}
if (-not (Test-Path -LiteralPath $toolboxRoot -PathType Container)) {
    Write-Error "AtlasToolbox root '$toolboxRoot' does not exist."
    exit 1
}

function Assert-LauncherIdentifier {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Name', 'State')]
        [string]$Kind,

        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    if ($Value -isnot [string] -or
        [string]::IsNullOrWhiteSpace([string]$Value) -or
        [string]$Value -cnotmatch '\A[A-Za-z][A-Za-z0-9]*\z') {
        throw "$Kind metadata from '$Source' must be a non-empty ASCII identifier beginning with a letter."
    }

    return [string]$Value
}

function Resolve-LauncherTargetPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$LauncherRelative,

        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    if (-not [IO.Path]::IsPathRooted($RootPath)) {
        throw "Launcher root '$RootPath' for '$Source' is not fully qualified."
    }
    if ($LauncherRelative -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$LauncherRelative)) {
        throw "Launcher metadata from '$Source' must be a non-empty relative .cmd path."
    }

    $relative = [string]$LauncherRelative
    if ([IO.Path]::IsPathRooted($relative) -or
        $relative.Contains('/') -or
        $relative -cnotmatch '\A[A-Za-z0-9 ._()\\-]+\z' -or
        -not $relative.EndsWith('.cmd', [StringComparison]::Ordinal)) {
        throw "Launcher metadata '$relative' from '$Source' is not a safe relative .cmd path."
    }

    $segments = @($relative.Split([char]'\'))
    foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment) -or
            $segment -in @('.', '..') -or
            $segment.EndsWith(' ', [StringComparison]::Ordinal) -or
            $segment.EndsWith('.', [StringComparison]::Ordinal) -or
            $segment.Split('.')[0] -match '\A(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])\z') {
            throw "Launcher metadata '$relative' from '$Source' contains an unsafe path segment."
        }
    }

    $rootFullPath = [IO.Path]::GetFullPath($RootPath).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $rootPrefix = $rootFullPath + [IO.Path]::DirectorySeparatorChar
    $launcherPath = [IO.Path]::GetFullPath([IO.Path]::Combine($rootFullPath, $relative))
    if (-not $launcherPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Launcher metadata '$relative' from '$Source' escapes its declared root."
    }

    return $launcherPath
}

function New-LauncherContent {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Name,

        [AllowNull()]
        [object]$State,

        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $validatedName = Assert-LauncherIdentifier -Value $Name -Kind Name -Source $Source
    $stateArgument = ''
    if ($PSBoundParameters.ContainsKey('State')) {
        $validatedState = Assert-LauncherIdentifier -Value $State -Kind State -Source $Source
        $stateArgument = ' -State "{0}"' -f $validatedState
    }

    $lines = @(
        '@echo off'
        'verify other 2>nul'
        'setlocal EnableExtensions DisableDelayedExpansion'
        'if errorlevel 1 exit /b 1'
        'cd /d "%__APPDIR__%"'
        'if errorlevel 1 exit /b 1'
        'for %%I in ("%__APPDIR__%..") do set "AtlasWindowsRoot=%%~fI"'
        'set "launcherEnvironment=%AtlasWindowsRoot%\AtlasModules\Scripts\Internal\Initialize-PowerShellLauncherEnvironment.cmd"'
        'if not exist "%launcherEnvironment%" ('
        '    echo PowerShell launcher environment helper not found: "%launcherEnvironment%"'
        '    exit /b 1'
        ')'
        'call "%launcherEnvironment%"'
        'if errorlevel 1 exit /b 1'
        'set "AtlasLauncherSilent="'
        'set "AtlasLauncherJustContext="'
        'set "AtlasLauncherNoAction="'
        ':AtlasLauncherParseArguments'
        'if "%~1"=="" goto AtlasLauncherRun'
        'if /i "%~1"=="/silent" goto AtlasLauncherFlagSilent'
        'if /i "%~1"=="-silent" goto AtlasLauncherFlagSilent'
        'if /i "%~1"=="/quiet" goto AtlasLauncherFlagSilent'
        'if /i "%~1"=="-quiet" goto AtlasLauncherFlagSilent'
        'if /i "%~1"=="/justcontext" goto AtlasLauncherFlagJustContext'
        'if /i "%~1"=="-justcontext" goto AtlasLauncherFlagJustContext'
        'if /i "%~1"=="/noaction" goto AtlasLauncherFlagNoAction'
        'if /i "%~1"=="-noaction" goto AtlasLauncherFlagNoAction'
        'exit /b 87'
        ':AtlasLauncherFlagSilent'
        'set "AtlasLauncherSilent=/silent"'
        'shift /1'
        'goto AtlasLauncherParseArguments'
        ':AtlasLauncherFlagJustContext'
        'set "AtlasLauncherJustContext=/justcontext"'
        'shift /1'
        'goto AtlasLauncherParseArguments'
        ':AtlasLauncherFlagNoAction'
        'set "AtlasLauncherNoAction=/noaction"'
        'shift /1'
        'goto AtlasLauncherParseArguments'
        ':AtlasLauncherRun'
        "`"%AtlasNativePowerShell%`" -NoProfile -NoLogo -ExecutionPolicy Bypass -File `"%AtlasWindowsRoot%\AtlasModules\Scripts\Invoke-Toggle.ps1`" -Name `"$validatedName`"$stateArgument -LauncherPath `"%~f0`" %AtlasLauncherSilent% %AtlasLauncherJustContext% %AtlasLauncherNoAction%"
        'if errorlevel 0 ('
        '    if errorlevel 1 exit /b'
        ') else ('
        '    exit /b 1'
        ')'
        'exit /b 0'
    )

    # Launchers are .cmd files and must be CRLF regardless of the environment.
    return ($lines -join "`r`n") + "`r`n"
}

# ---- Collect the expected launcher set from the definitions -----------------------------
$problems = New-Object System.Collections.Generic.List[string]
# Key: launcher full path (lowercase). Value: @{ Path; Content; Source }
$expected = @{}

function Add-ExpectedLauncher {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$LauncherRelative,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$ToggleName,

        [AllowNull()]
        [object]$StateName,

        [Parameter(Mandatory = $true)]
        [string]$Source,

        # Root the launcher is relative to; defaults to the AtlasDesktop tree, overridden to
        # the Toolbox tree for ToolboxLauncher declarations.
        [string]$RootPath = $desktopRoot
    )

    try {
        $validatedName = Assert-LauncherIdentifier -Value $ToggleName -Kind Name -Source $Source
        $launcherPath = Resolve-LauncherTargetPath `
            -RootPath $RootPath `
            -LauncherRelative $LauncherRelative `
            -Source $Source
        $contentParameters = @{
            Name   = $validatedName
            Source = $Source
        }
        if ($PSBoundParameters.ContainsKey('StateName')) {
            $contentParameters.State = Assert-LauncherIdentifier `
                -Value $StateName `
                -Kind State `
                -Source $Source
        }
        $launcherContent = New-LauncherContent @contentParameters
    }
    catch {
        $problems.Add("Invalid launcher declaration from '$Source': $($_.Exception.Message)")
        return
    }

    $key = $launcherPath.ToLowerInvariant()
    if ($expected.ContainsKey($key)) {
        $problems.Add("Duplicate launcher target '$LauncherRelative' (declared by '$Source' and '$($expected[$key].Source)').")
        return
    }

    $expected[$key] = @{
        Path    = $launcherPath
        Content = $launcherContent
        Source  = $Source
    }
}

foreach ($definitionFile in @(Get-ChildItem -LiteralPath $togglesRoot -Recurse -File -Filter '*.ps1')) {
    try {
        $definition = & $definitionFile.FullName
    }
    catch {
        $problems.Add("Failed to load toggle definition '$($definitionFile.FullName)': $($_.Exception.Message)")
        continue
    }

    if ($definition -isnot [System.Collections.IDictionary] -or
        -not $definition.Contains('Name') -or $definition.Name -isnot [string] -or
        [string]::IsNullOrWhiteSpace([string]$definition.Name) -or
        -not $definition.Contains('States') -or $definition.States -isnot [System.Collections.IDictionary]) {
        $problems.Add("Toggle definition '$($definitionFile.FullName)' does not return a hashtable with 'Name' and 'States'.")
        continue
    }

    try {
        $toggleName = Assert-LauncherIdentifier `
            -Value $definition.Name `
            -Kind Name `
            -Source $definitionFile.FullName
    }
    catch {
        $problems.Add($_.Exception.Message)
        continue
    }
    if ($toggleName -ne $definitionFile.BaseName) {
        $problems.Add("Toggle definition '$($definitionFile.FullName)' declares Name '$toggleName' but its file name requires '$($definitionFile.BaseName)'.")
        continue
    }

    # Menu toggles: one top-level launcher without -State.
    if ($definition.Contains('Launcher') -and $definition.Launcher) {
        Add-ExpectedLauncher -LauncherRelative $definition.Launcher -ToggleName $toggleName -Source $definitionFile.FullName
    }
    # Definition-level Toolbox launcher (single-launcher / Menu toggles surfaced in the Toolbox).
    if ($definition.Contains('ToolboxLauncher') -and $definition.ToolboxLauncher) {
        Add-ExpectedLauncher -LauncherRelative $definition.ToolboxLauncher -ToggleName $toggleName -Source $definitionFile.FullName -RootPath $toolboxRoot
    }

    foreach ($stateName in @($definition.States.Keys)) {
        $stateEntry = $definition.States[$stateName]
        if ($stateEntry -isnot [System.Collections.IDictionary]) {
            $problems.Add("Toggle definition '$($definitionFile.FullName)' state '$stateName' is not a hashtable.")
            continue
        }
        if ($stateEntry.Contains('Launcher') -and $stateEntry.Launcher) {
            Add-ExpectedLauncher -LauncherRelative $stateEntry.Launcher -ToggleName $toggleName -StateName $stateName -Source $definitionFile.FullName
        }
        if ($stateEntry.Contains('ToolboxLauncher') -and $stateEntry.ToolboxLauncher) {
            Add-ExpectedLauncher -LauncherRelative $stateEntry.ToolboxLauncher -ToggleName $toggleName -StateName $stateName -Source $definitionFile.FullName -RootPath $toolboxRoot
        }
    }
}

# ---- Validate or generate ----------------------------------------------------------------
if ($Validate) {
    foreach ($entry in $expected.Values) {
        if (-not (Test-Path -LiteralPath $entry.Path -PathType Leaf)) {
            $problems.Add("Missing launcher: '$($entry.Path)' (declared by '$($entry.Source)').")
            continue
        }

        $actual = [System.IO.File]::ReadAllText($entry.Path)
        if ($actual -cne $entry.Content) {
            $problems.Add("Launcher drift: '$($entry.Path)' does not match its definition '$($entry.Source)'. Re-run New-ToggleLaunchers.ps1.")
        }
    }

    # Orphans: launcher-style .cmd files pointing at Invoke-Toggle.ps1 with no definition
    # (checked across both the AtlasDesktop and Toolbox trees).
    foreach ($orphanRoot in @($desktopRoot, $toolboxRoot)) {
        foreach ($cmdFile in @(Get-ChildItem -LiteralPath $orphanRoot -Recurse -File -Filter '*.cmd')) {
            $content = [System.IO.File]::ReadAllText($cmdFile.FullName)
            if ($content -match 'Invoke-Toggle\.ps1' -and -not $expected.ContainsKey($cmdFile.FullName.ToLowerInvariant())) {
                $problems.Add("Orphan launcher: '$($cmdFile.FullName)' calls Invoke-Toggle.ps1 but no toggle definition declares it.")
            }
        }
    }

    if ($problems.Count -gt 0) {
        foreach ($problem in $problems) {
            Write-Host "PROBLEM: $problem" -ForegroundColor Red
        }
        Write-Host "Launcher validation failed with $($problems.Count) problem(s)." -ForegroundColor Red
        exit 1
    }

    Write-Host "Launcher validation clean: $($expected.Count) launcher(s) match their definitions." -ForegroundColor Green
    exit 0
}

if ($problems.Count -gt 0) {
    foreach ($problem in $problems) {
        Write-Host "PROBLEM: $problem" -ForegroundColor Red
    }
    Write-Host 'Fix the definition problems above before generating launchers.' -ForegroundColor Red
    exit 1
}

$written = 0
$unchanged = 0
foreach ($entry in $expected.Values) {
    $directory = Split-Path -Parent $entry.Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    if ((Test-Path -LiteralPath $entry.Path -PathType Leaf) -and
        ([System.IO.File]::ReadAllText($entry.Path) -ceq $entry.Content)) {
        $unchanged++
        continue
    }

    [System.IO.File]::WriteAllText($entry.Path, $entry.Content, [System.Text.Encoding]::ASCII)
    Write-Host "Wrote: $($entry.Path)"
    $written++
}

Write-Host "Done: $written launcher(s) written, $unchanged unchanged." -ForegroundColor Green
exit 0
