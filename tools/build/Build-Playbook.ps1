<#
.SYNOPSIS
    Builds the Atlas playbook into an .apbx package (a renamed, password-protected ZIP
    understood by AME Wizard).
.DESCRIPTION
    Thin entry point over the AtlasBuild module. Runs from any working directory; the
    playbook location defaults to the repository's playbook/ directory.
.PARAMETER Removals
    Dev-build content removals:
      Requirements       - strip <Requirement> pre-flight gates from playbook.conf
      WinverRequirement  - strip <SupportedBuilds> from playbook.conf
      Verification       - strip <ProductCode> from playbook.conf
#>
#requires -Version 7.0
Param(
    [switch]$LocalTest,
    [switch]$ReplaceOldPlaybook,
    [switch]$DontOpenPbLocation,
    [switch]$NoPassword,
    [ValidateSet('Requirements', 'WinverRequirement', 'Verification', IgnoreCase = $true)]
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
    # One argument-safe profile shared by build.cmd and build.sh. In particular, native
    # `pwsh -File` cannot bind a comma-separated command-line token to string[] reliably,
    # so the wrappers should not reconstruct a PowerShell command string just to express
    # these two removals.
    $ReplaceOldPlaybook = $true
    $DontOpenPbLocation = $true
    $profileRemovals = @('WinverRequirement', 'Verification')
}

if (-not $PlaybookPath) {
    # Prefer the current directory when it is (or contains) a playbook, so existing
    # "run from the playbook folder" workflows keep working; fall back to the repo layout.
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
    -RemoveVerification:$removalSet.ContainsKey('verification') `
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
