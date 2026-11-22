<#
.SYNOPSIS
    Builds the Atlas package (.atlaspkg) from the package/ folder.
.DESCRIPTION
    Thin entry point over the AtlasBuild module. The package is a ZIP archive whose entries
    are encrypted with AES-256 under the public password that docs/package-format.md
    describes. Runs from any working directory; the source defaults to the repository's
    package/ folder. Every build is verified with Test-Package.ps1 before it's published
    beside the source or in -OutputPath.
.PARAMETER LocalTest
    The profile for a quick test build, such as the package Atlas Manager's tests embed:
    implies -ReplaceExisting, -NoExplorer and the SupportedBuilds removal, so the front
    door refuses to install it.
.PARAMETER ReplaceExisting
    Replaces an existing package of the same name instead of adding a number to the new
    one's name.
.PARAMETER NoExplorer
    Doesn't open File Explorer at the built package.
.PARAMETER NoPassword
    Builds the archive without encryption.
.PARAMETER Removals
    Test-build changes to the packaged atlas.json:
      Requirements: empties requirements, so the front door runs only the checks it always runs.
      SupportedBuilds: empties supportedBuilds, so the front door refuses the package.
.PARAMETER FileName
    The package's file name without the .atlaspkg extension. The default is "Atlas Test".
.PARAMETER PackagePath
    The package source folder. The default is the current folder when it holds atlas.json
    and Executables, then a package/ folder below it, then the repository's package/.
.PARAMETER OutputPath
    The folder the package is written to. The default is the package source folder.
.NOTES
    Exit codes: 0 when the package is built and verified, 1 otherwise.
#>
#requires -Version 7.0
Param(
    [switch]$LocalTest,
    [switch]$ReplaceExisting,
    [switch]$NoExplorer,
    [switch]$NoPassword,
    [ValidateSet('Requirements', 'SupportedBuilds', IgnoreCase = $true)]
    [string[]]$Removals,
    [string]$FileName = 'Atlas Test',
    [string]$PackagePath,
    [string]$OutputPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$buildStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'AtlasBuild\AtlasBuild.psd1') -Force

$profileRemovals = @()
if ($LocalTest) {
    # One argument-safe profile shared by build.cmd and build.sh. Native `pwsh -File`
    # can't bind a comma-separated command-line token to string[] reliably, so the
    # wrappers shouldn't rebuild a PowerShell command string to express this removal.
    $ReplaceExisting = $true
    $NoExplorer = $true
    $profileRemovals = @('SupportedBuilds')
}

if (-not $PackagePath) {
    # Prefer the current directory when it is (or contains) the package source, so
    # running from the package/ folder keeps working; fall back to the repository layout.
    $isPackageSource = {
        param([string]$Path)
        (Test-Path -LiteralPath (Join-Path -Path $Path -ChildPath 'atlas.json') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path -Path $Path -ChildPath 'Executables') -PathType Container)
    }
    $currentPath = (Get-Location).ProviderPath
    if (& $isPackageSource $currentPath) {
        $PackagePath = $currentPath
    }
    elseif (& $isPackageSource (Join-Path -Path $currentPath -ChildPath 'package')) {
        $PackagePath = Join-Path -Path $currentPath -ChildPath 'package'
    }
    else {
        $PackagePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\package'
    }
}

$removalSet = @{}
foreach ($removal in @($Removals) + @($profileRemovals)) {
    if ($removal) {
        $removalSet[$removal.ToLowerInvariant()] = $true
    }
}

$packageFile = New-AtlasPackage `
    -PackagePath $PackagePath `
    -OutputDirectory $OutputPath `
    -FileName $FileName `
    -RemoveRequirements:$removalSet.ContainsKey('requirements') `
    -RemoveSupportedBuilds:$removalSet.ContainsKey('supportedbuilds') `
    -NoPassword:$NoPassword `
    -ReplaceExisting:$ReplaceExisting

$buildStopwatch.Stop()
$elapsedSeconds = [Math]::Round($buildStopwatch.Elapsed.TotalSeconds, 2)
Write-Host ("Built successfully in {0}s! Path: `"{1}`"" -f $elapsedSeconds, $packageFile) -ForegroundColor Green

if (-not $NoExplorer) {
    $isWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows)
    if ($isWindowsPlatform) {
        Start-Process -FilePath 'explorer.exe' -ArgumentList "/select,`"$packageFile`""
    }
    else {
        Write-Warning "Can't open the package's folder because the system isn't Windows."
    }
}
