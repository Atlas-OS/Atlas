<#
.SYNOPSIS
    Builds the Atlas package (.apbx), a renamed, password-protected ZIP of the playbook/
    folder.
.DESCRIPTION
    Thin entry point over the AtlasBuild module. Runs from any working directory; the
    source defaults to the repository's playbook/ folder. Every build is verified with
    Test-Apbx.ps1 before it's published beside the source or in -OutputPath.
.PARAMETER LocalTest
    The profile for a package to test on a PC or VM: implies -ReplaceOldPlaybook,
    -DontOpenPbLocation and the WinverRequirement removal.
.PARAMETER ReplaceOldPlaybook
    Replaces an existing package of the same name instead of adding a number to the
    new one's name.
.PARAMETER DontOpenPbLocation
    Doesn't open File Explorer at the built package.
.PARAMETER NoPassword
    Builds the archive without its password.
.PARAMETER Removals
    Test-build content removals:
      Requirements: strips the <Requirement> checks from playbook.conf.
      WinverRequirement: strips <SupportedBuilds> from playbook.conf.
.PARAMETER FileName
    The package's file name without the .apbx extension. The default is "Atlas Test".
.PARAMETER PlaybookPath
    The package source folder. The default is the current folder when it holds
    playbook.conf, then a playbook/ folder below it, then the repository's playbook/.
.PARAMETER OutputPath
    The folder the package is written to. The default is the package source folder.
#>
#requires -Version 7.0
Param(
    [switch]$LocalTest,
    [switch]$ReplaceOldPlaybook,
    [switch]$DontOpenPbLocation,
    [switch]$NoPassword,
    [ValidateSet('Requirements', 'WinverRequirement', IgnoreCase = $true)]
    [string[]]$Removals,
    [string]$FileName = 'Atlas Test',
    [string]$PlaybookPath,
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
    $ReplaceOldPlaybook = $true
    $DontOpenPbLocation = $true
    $profileRemovals = @('WinverRequirement')
}

if (-not $PlaybookPath) {
    # Prefer the current directory when it is (or contains) the package source, so
    # running from the playbook/ folder keeps working; fall back to the repo layout.
    if (Test-Path -LiteralPath 'playbook.conf' -PathType Leaf) {
        $PlaybookPath = (Get-Location).ProviderPath
    }
    elseif (Test-Path -LiteralPath 'playbook\playbook.conf' -PathType Leaf) {
        $PlaybookPath = Join-Path -Path (Get-Location).ProviderPath -ChildPath 'playbook'
    }
    else {
        $PlaybookPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\playbook'
    }
}

$removalSet = @{}
foreach ($removal in @($Removals) + @($profileRemovals)) {
    if ($removal) {
        $removalSet[$removal.ToLowerInvariant()] = $true
    }
}

$apbxPath = New-Apbx `
    -PlaybookPath $PlaybookPath `
    -OutputDirectory $OutputPath `
    -FileName $FileName `
    -RemoveRequirements:$removalSet.ContainsKey('requirements') `
    -RemoveWinverRequirement:$removalSet.ContainsKey('winverrequirement') `
    -NoPassword:$NoPassword `
    -ReplaceOldPlaybook:$ReplaceOldPlaybook

$buildStopwatch.Stop()
$elapsedSeconds = [Math]::Round($buildStopwatch.Elapsed.TotalSeconds, 2)
Write-Host ("Built successfully in {0}s! Path: `"{1}`"" -f $elapsedSeconds, $apbxPath) -ForegroundColor Green

if (-not $DontOpenPbLocation) {
    $isWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows)
    if ($isWindowsPlatform) {
        Start-Process -FilePath 'explorer.exe' -ArgumentList "/select,`"$apbxPath`""
    }
    else {
        Write-Warning "Can't open the APBX directory because the system isn't Windows."
    }
}
