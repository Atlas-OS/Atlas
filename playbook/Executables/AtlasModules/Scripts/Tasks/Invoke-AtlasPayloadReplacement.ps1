<#
.SYNOPSIS
    Replaces the installed Atlas payload from the extracted playbook.
.DESCRIPTION
    The committed install state decides whether an existing payload must be
    stopped and removed. Replacement is blocked while a CBS retry is pending so
    the recovery command cannot be deleted underneath Safe Mode.
#>

[CmdletBinding()]
param(
    [switch]$VerifyOnly,
    [switch]$LibraryOnly
)

$trustBootstrap = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $PSScriptRoot, '..', 'Internal', 'Initialize-PowerShellTrust.ps1'
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
        throw "Payload replacement requires a Running install state, not '$($InstallState.status)'."
    }
    if (@('Fresh', 'Upgrade', 'Reapply') -cnotcontains [string]$InstallState.mode) {
        throw "Payload replacement does not support install mode '$($InstallState.mode)'."
    }
    if ($InstallState.isOobe -isnot [bool]) {
        throw 'Install state isOobe must be a Boolean.'
    }

    $hasInstalledPayload = [string]$InstallState.mode -cne 'Fresh'
    return [pscustomobject][ordered]@{
        Mode                   = [string]$InstallState.mode
        StopInstalledPayload   = $hasInstalledPayload
        RemoveInstalledPayload = $hasInstalledPayload -and -not [bool]$InstallState.isOobe
    }
}

function Assert-AtlasPayloadReplacementAllowed {
    $retryState = Read-AtlasCbsRetryState
    if ($null -ne $retryState) {
        throw "Atlas payload replacement is blocked while CBS retry state is '$($retryState.Phase)'."
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
            throw "Required extracted payload directory '$source' is missing."
        }
        if (-not [IO.Directory]::Exists($destination)) {
            throw "Installed Atlas payload directory '$destination' is missing."
        }
    }

    $installedBootstrap = Join-Path -Path $destinationRoot -ChildPath 'AtlasModules\initPowerShell.ps1'
    if (-not [IO.File]::Exists($installedBootstrap)) {
        throw "Installed Atlas payload bootstrap '$installedBootstrap' is missing."
    }

    $themesSource = Join-Path -Path $sourceRoot -ChildPath 'Themes'
    if (-not [IO.Directory]::Exists($themesSource)) {
        throw "Required extracted Themes payload directory '$themesSource' is missing."
    }
    $themesDestination = Join-Path -Path $destinationRoot -ChildPath 'Resources\Themes'
    foreach ($theme in @(Get-ChildItem -LiteralPath $themesSource -Force -ErrorAction Stop)) {
        $installedTheme = Join-Path -Path $themesDestination -ChildPath $theme.Name
        $installedItem = Get-Item -LiteralPath $installedTheme -Force -ErrorAction SilentlyContinue
        if ($null -eq $installedItem -or $installedItem.PSIsContainer -ne $theme.PSIsContainer) {
            throw "Installed Atlas theme payload '$installedTheme' is missing."
        }
    }
}

function Invoke-AtlasPayloadReplacementCore {
    [CmdletBinding()]
    param(
        [AllowNull()][psobject]$Plan,
        [switch]$VerifyOnly
    )

    if ($VerifyOnly) {
        Assert-AtlasPayloadInstalled -ExtractedExecutablesRoot $script:AtlasExtractedExecutablesRoot `
            -WindowsPath $script:AtlasWindowsPath
        return
    }
    if ($null -eq $Plan) {
        throw 'A payload replacement plan is required.'
    }

    Assert-AtlasPayloadReplacementAllowed
    if ([bool]$Plan.StopInstalledPayload) {
        Invoke-AtlasInstalledPayloadStop
        Invoke-AtlasProcessExplorerStop
    }
    if ([bool]$Plan.RemoveInstalledPayload) {
        Invoke-AtlasInstalledPayloadRemove
    }
    Invoke-AtlasExtractedPayloadCopy
    Assert-AtlasPayloadInstalled -ExtractedExecutablesRoot $script:AtlasExtractedExecutablesRoot `
        -WindowsPath $script:AtlasWindowsPath
}

if ($LibraryOnly) {
    return
}

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, '..'))
$script:AtlasExtractedExecutablesRoot = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $scriptsRoot, '..', '..'
    ))
$script:AtlasWindowsPath = [Environment]::GetFolderPath('Windows')
if ([string]::IsNullOrWhiteSpace($script:AtlasWindowsPath) -or
    -not [IO.Directory]::Exists($script:AtlasWindowsPath)) {
    throw "Windows directory '$($script:AtlasWindowsPath)' is not available."
}
if ($VerifyOnly) {
    Invoke-AtlasPayloadReplacementCore -VerifyOnly
    return
}

$script:AtlasStopInstalledPayloadScript = Join-Path -Path $scriptsRoot `
    -ChildPath 'Internal\Stop-AtlasFolderProcess.ps1'
$script:AtlasStopProcessExplorerScript = Join-Path -Path $PSScriptRoot `
    -ChildPath 'Stop-ProcessExplorerUpgrade.ps1'
$script:AtlasRemoveInstalledPayloadScript = Join-Path -Path $PSScriptRoot `
    -ChildPath 'Remove-PreviousAtlasInstall.ps1'
$script:AtlasCopyPayloadScript = Join-Path -Path $PSScriptRoot -ChildPath 'Copy-AtlasPayload.ps1'
$cbsRetryScript = Join-Path -Path $scriptsRoot -ChildPath 'Internal\CbsRetry.ps1'
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
        throw "Required extracted payload-replacement file is missing at '$requiredFile'."
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
