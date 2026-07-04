<#
.SYNOPSIS
    Generates the AtlasDesktop .cmd launchers from the toggle definitions under
    playbook\Executables\AtlasModules\Toggles.
.DESCRIPTION
    Every toggle state that declares a 'Launcher' (AtlasDesktop-relative path) gets a
    4-line CRLF .cmd launcher that forwards to Invoke-Toggle.ps1, preserving the
    /silent (and other) flag surface via %*. Menu definitions declare a single top-level
    'Launcher' and their launcher omits -State.

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

function New-LauncherContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$State
    )

    $stateArgument = ''
    if ($State) {
        $stateArgument = " -State $State"
    }

    $lines = @(
        '@echo off'
        "title $Title"
        "powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File `"%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1`" -Name $Name$stateArgument -LauncherPath `"%~f0`" %*"
        'exit /b %errorlevel%'
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
        [string]$LauncherRelative,

        [Parameter(Mandatory = $true)]
        [string]$ToggleName,

        [string]$StateName,

        [Parameter(Mandatory = $true)]
        [string]$Source,

        # Root the launcher is relative to; defaults to the AtlasDesktop tree, overridden to
        # the Toolbox tree for ToolboxLauncher declarations.
        [string]$RootPath = $desktopRoot
    )

    $launcherPath = Join-Path -Path $RootPath -ChildPath $LauncherRelative
    $key = $launcherPath.ToLowerInvariant()
    if ($expected.ContainsKey($key)) {
        $problems.Add("Duplicate launcher target '$LauncherRelative' (declared by '$Source' and '$($expected[$key].Source)').")
        return
    }

    $title = [System.IO.Path]::GetFileNameWithoutExtension($launcherPath)
    $expected[$key] = @{
        Path    = $launcherPath
        Content = New-LauncherContent -Title $title -Name $ToggleName -State $StateName
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
        -not $definition.Contains('Name') -or [string]::IsNullOrWhiteSpace([string]$definition.Name) -or
        -not $definition.Contains('States') -or $definition.States -isnot [System.Collections.IDictionary]) {
        $problems.Add("Toggle definition '$($definitionFile.FullName)' does not return a hashtable with 'Name' and 'States'.")
        continue
    }

    $toggleName = [string]$definition.Name
    if ($toggleName -ne $definitionFile.BaseName) {
        $problems.Add("Toggle definition '$($definitionFile.FullName)' declares Name '$toggleName' but its file name requires '$($definitionFile.BaseName)'.")
        continue
    }

    # Menu toggles: one top-level launcher without -State.
    if ($definition.Contains('Launcher') -and $definition.Launcher) {
        Add-ExpectedLauncher -LauncherRelative ([string]$definition.Launcher) -ToggleName $toggleName -Source $definitionFile.FullName
    }
    # Definition-level Toolbox launcher (single-launcher / Menu toggles surfaced in the Toolbox).
    if ($definition.Contains('ToolboxLauncher') -and $definition.ToolboxLauncher) {
        Add-ExpectedLauncher -LauncherRelative ([string]$definition.ToolboxLauncher) -ToggleName $toggleName -Source $definitionFile.FullName -RootPath $toolboxRoot
    }

    foreach ($stateName in @($definition.States.Keys)) {
        $stateEntry = $definition.States[$stateName]
        if ($stateEntry -isnot [System.Collections.IDictionary]) {
            $problems.Add("Toggle definition '$($definitionFile.FullName)' state '$stateName' is not a hashtable.")
            continue
        }
        if ($stateEntry.Contains('Launcher') -and $stateEntry.Launcher) {
            Add-ExpectedLauncher -LauncherRelative ([string]$stateEntry.Launcher) -ToggleName $toggleName -StateName ([string]$stateName) -Source $definitionFile.FullName
        }
        if ($stateEntry.Contains('ToolboxLauncher') -and $stateEntry.ToolboxLauncher) {
            Add-ExpectedLauncher -LauncherRelative ([string]$stateEntry.ToolboxLauncher) -ToggleName $toggleName -StateName ([string]$stateName) -Source $definitionFile.FullName -RootPath $toolboxRoot
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
