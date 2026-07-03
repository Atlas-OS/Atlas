<#
.SYNOPSIS
    Builds the Atlas playbook into an .apbx package (a renamed, password-protected ZIP
    understood by AME Wizard).
.DESCRIPTION
    Thin entry point over the AtlasBuild module. Runs from any working directory; the
    playbook location defaults to the repository's playbook/ directory.
.PARAMETER Removals
    Dev-build content removals:
      Dependencies       - strip the "NO LOCAL BUILD" block from start.yml
      Requirements       - strip <Requirement> pre-flight gates from playbook.conf
      WinverRequirement  - strip <SupportedBuilds> from playbook.conf
      Verification       - strip <ProductCode> from playbook.conf
#>
Param(
    [switch]$AddLiveLog,
    [switch]$ReplaceOldPlaybook,
    [switch]$DontOpenPbLocation,
    [switch]$NoPassword,
    [ValidateSet('Dependencies', 'Requirements', 'WinverRequirement', 'Verification', IgnoreCase = $true)]
    [string[]]$Removals,
    [string]$FileName = 'Atlas Test',
    [string]$PlaybookPath,
    [string]$OutputPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$buildStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'AtlasBuild\AtlasBuild.psd1') -Force

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
foreach ($removal in @($Removals)) {
    if ($removal) {
        $removalSet[$removal.ToLowerInvariant()] = $true
    }
}

$apbxPath = New-Apbx `
    -PlaybookPath $PlaybookPath `
    -OutputDirectory $OutputPath `
    -FileName $FileName `
    -AddLiveLog:$AddLiveLog `
    -RemoveDependencies:$removalSet.ContainsKey('dependencies') `
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
