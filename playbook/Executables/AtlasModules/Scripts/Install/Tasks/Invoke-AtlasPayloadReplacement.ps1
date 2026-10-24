<#
.SYNOPSIS
    Replaces the installed Atlas files with those from the extracted package.
.DESCRIPTION
    The committed install state decides whether an existing installation must be
    stopped and removed. Replacement is blocked while a CBS retry is armed, so the
    recovery command can't be deleted underneath Safe Mode. A retry that was never
    armed, and the Safe Mode package list Atlas 0.5 left in System32, are given up first.
#>

[CmdletBinding()]
param(
    [switch]$LibraryOnly
)

$trustBootstrap = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $PSScriptRoot, '..', '..', 'Initialize-AtlasPowerShell.ps1'
    ))
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Resolve-AtlasPayloadReplacementPlan {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$InstallState)

    foreach ($property in @('status', 'mode', 'isOobe')) {
        if ($null -eq $InstallState.PSObject.Properties[$property]) {
            throw "Install state is missing required '$property' field."
        }
    }
    if ([string]$InstallState.status -cne 'Running') {
        throw "Replacing Atlas's files requires a Running install state, not '$($InstallState.status)'."
    }
    if (@('Fresh', 'Upgrade', 'Reapply', 'Rebase') -cnotcontains [string]$InstallState.mode) {
        throw "Replacing Atlas's files does not support install mode '$($InstallState.mode)'."
    }
    if ($InstallState.isOobe -isnot [bool]) {
        throw 'Install state isOobe must be a Boolean.'
    }

    $hasInstalledPayload = [string]$InstallState.mode -cne 'Fresh'
    $completedSteps = @()
    if ($null -ne $InstallState.PSObject.Properties['completedSteps']) {
        $completedSteps = @($InstallState.completedSteps)
    }
    return [pscustomobject][ordered]@{
        Mode                   = [string]$InstallState.mode
        StopInstalledPayload   = $hasInstalledPayload
        RemoveInstalledPayload = $hasInstalledPayload -and -not [bool]$InstallState.isOobe
        ChoicesReplayed        = $completedSteps -icontains 'Defaults'
    }
}

function Assert-AtlasPayloadReplacementAllowed {
    Remove-AtlasLegacyCbsRetryList
    Clear-AtlasUnarmedCbsRetry
    $retryState = Read-AtlasCbsRetryState
    if ($null -ne $retryState) {
        throw "Replacing Atlas's files is blocked while the CBS retry state is '$($retryState.Phase)' ('$(Get-AtlasCbsRetryStatePath)'). $(Get-AtlasCbsRetryInstruction -Phase ([string]$retryState.Phase))"
    }
}

function Invoke-AtlasInstalledPayloadStop {
    & $script:AtlasStopInstalledPayloadScript
}

function Invoke-AtlasProcessExplorerStop {
    & $script:AtlasStopProcessExplorerScript
}

function Invoke-AtlasInstalledPayloadRemove {
    & $script:AtlasRemoveInstalledPayloadScript
}

function Invoke-AtlasExtractedPayloadCopy {
    & $script:AtlasCopyPayloadScript
}

function Test-AtlasProcessExplorerChoiceEnabled {
    $statePath = 'HKLM:\SOFTWARE\AtlasOS\Services\ProcessExplorer'
    if (-not (Test-Path -LiteralPath $statePath)) {
        return $false
    }
    $stateKey = Get-Item -LiteralPath $statePath -ErrorAction Stop
    return @($stateKey.GetValueNames()) -contains 'state' -and
        $stateKey.GetValueKind('state') -eq [Microsoft.Win32.RegistryValueKind]::DWord -and
        [int]$stateKey.GetValue('state') -eq 1
}

function Invoke-AtlasProcessExplorerRestore {
    # The same package operation the Defaults replay runs, which leaves pcw as it is.
    try {
        . ([IO.Path]::Combine($script:AtlasWindowsPath, 'AtlasModules', 'Scripts', 'Operations', 'ProcessExplorer-Package.ps1'))
        Install-AtlasProcessExplorerPackage
    }
    catch {
        throw "Reinstalling Process Explorer for the recorded ProcessExplorer choice failed: $($_.Exception.Message)"
    }
    Write-Output 'Reinstalled Process Explorer for the recorded ProcessExplorer choice.'
}

function Assert-AtlasPayloadInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ExtractedExecutablesRoot,
        [Parameter(Mandatory = $true)][string]$WindowsPath
    )

    $sourceRoot = [IO.Path]::GetFullPath($ExtractedExecutablesRoot)
    $destinationRoot = [IO.Path]::GetFullPath($WindowsPath)
    foreach ($directory in @('AtlasModules', 'AtlasDesktop')) {
        $source = Join-Path -Path $sourceRoot -ChildPath $directory
        $destination = Join-Path -Path $destinationRoot -ChildPath $directory
        if (-not [IO.Directory]::Exists($source)) {
            throw "Required extracted directory '$source' is missing."
        }
        if (-not [IO.Directory]::Exists($destination)) {
            throw "Installed Atlas directory '$destination' is missing."
        }
    }

    $installedBootstrap = Join-Path -Path $destinationRoot -ChildPath 'AtlasModules\Scripts\Initialize-AtlasPowerShell.ps1'
    if (-not [IO.File]::Exists($installedBootstrap)) {
        throw "Installed Atlas bootstrap '$installedBootstrap' is missing."
    }

    $themesSource = Join-Path -Path $sourceRoot -ChildPath 'Themes'
    if (-not [IO.Directory]::Exists($themesSource)) {
        throw "Required extracted Themes directory '$themesSource' is missing."
    }
    $themesDestination = Join-Path -Path $destinationRoot -ChildPath 'Resources\Themes'
    foreach ($theme in @(Get-ChildItem -LiteralPath $themesSource -Force -ErrorAction Stop)) {
        $installedTheme = Join-Path -Path $themesDestination -ChildPath $theme.Name
        $installedItem = Get-Item -LiteralPath $installedTheme -Force -ErrorAction SilentlyContinue
        if ($null -eq $installedItem -or $installedItem.PSIsContainer -ne $theme.PSIsContainer) {
            throw "Installed Atlas theme '$installedTheme' is missing."
        }
    }
}

function Invoke-AtlasPayloadReplacementCore {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$Plan)

    Assert-AtlasPayloadReplacementAllowed
    $restoreProcessExplorer = $false
    if ([bool]$Plan.StopInstalledPayload) {
        # The teardown below removes an enabled Process Explorer and Defaults puts it
        # back, but a resumed install skips Defaults once it has completed.
        $restoreProcessExplorer = [bool]$Plan.ChoicesReplayed -and (Test-AtlasProcessExplorerChoiceEnabled)
        Invoke-AtlasInstalledPayloadStop
        Invoke-AtlasProcessExplorerStop
    }
    if ([bool]$Plan.RemoveInstalledPayload) {
        Invoke-AtlasInstalledPayloadRemove
    }
    Invoke-AtlasExtractedPayloadCopy
    Assert-AtlasPayloadInstalled -ExtractedExecutablesRoot $script:AtlasExtractedExecutablesRoot `
        -WindowsPath $script:AtlasWindowsPath
    if ($restoreProcessExplorer) {
        Invoke-AtlasProcessExplorerRestore
    }
}

if ($LibraryOnly) {
    return
}

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, '..', '..'))
$script:AtlasExtractedExecutablesRoot = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $scriptsRoot, '..', '..'
    ))
$script:AtlasWindowsPath = [Environment]::GetFolderPath('Windows')
if ([string]::IsNullOrWhiteSpace($script:AtlasWindowsPath) -or
    -not [IO.Directory]::Exists($script:AtlasWindowsPath)) {
    throw "Windows directory '$($script:AtlasWindowsPath)' is not available."
}

$script:AtlasStopInstalledPayloadScript = Join-Path -Path $PSScriptRoot `
    -ChildPath 'Stop-AtlasFolderProcess.ps1'
$script:AtlasStopProcessExplorerScript = Join-Path -Path $PSScriptRoot `
    -ChildPath 'Stop-ProcessExplorerUpgrade.ps1'
$script:AtlasRemoveInstalledPayloadScript = Join-Path -Path $PSScriptRoot `
    -ChildPath 'Remove-PreviousAtlasInstall.ps1'
$script:AtlasCopyPayloadScript = Join-Path -Path $PSScriptRoot -ChildPath 'Copy-AtlasPayload.ps1'
$cbsRetryScript = Join-Path -Path $scriptsRoot -ChildPath 'Operations\CbsRetry.ps1'
$installStateManifest = Join-Path -Path $scriptsRoot `
    -ChildPath 'Modules\Atlas.InstallState\Atlas.InstallState.psd1'

foreach ($requiredFile in @(
        $script:AtlasStopInstalledPayloadScript,
        $script:AtlasStopProcessExplorerScript,
        $script:AtlasRemoveInstalledPayloadScript,
        $script:AtlasCopyPayloadScript,
        $cbsRetryScript,
        $installStateManifest
    )) {
    if (-not [IO.File]::Exists($requiredFile)) {
        throw "Required extracted file is missing at '$requiredFile'."
    }
}

. $cbsRetryScript -LibraryOnly
Import-Module -Name $installStateManifest -Force -DisableNameChecking -ErrorAction Stop

$installState = Get-AtlasInstallState
if ($null -eq $installState) {
    throw 'No Atlas install state is active.'
}
$plan = Resolve-AtlasPayloadReplacementPlan -InstallState $installState
Invoke-AtlasPayloadReplacementCore -Plan $plan

# Removing the previous files took the Atlas packages' repair source with them. The
# Features phase recreates it but runs once, so a retried install recreates it here,
# and Windows never names a repair source that is gone.
if ([bool]$plan.RemoveInstalledPayload) {
    try {
        $installedScripts = [IO.Path]::Combine($script:AtlasWindowsPath, 'AtlasModules', 'Scripts')
        . ([IO.Path]::Combine($installedScripts, 'Preparation', 'WindowsTransition.ps1'))
        Import-Module -Name ([IO.Path]::Combine($installedScripts, 'Modules', 'Atlas.Software', 'Atlas.Software.psd1')) -ErrorAction Stop
        Write-Output "Atlas packages' repair source: $(Update-AtlasCbsRepairSource -AtlasPackages @(Get-AtlasInstalledAtlasPackage))."
    }
    catch {
        Write-Warning "The Atlas packages' repair source was not checked after replacing Atlas's files: $($_.Exception.Message)"
    }
}
