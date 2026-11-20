<#
.SYNOPSIS
    Reports what Atlas installed on this machine and what has since drifted.
.DESCRIPTION
    Reads the machine state document, then verifies every recorded AtlasDesktop toggle
    state and every applicable install tweak against the live machine: registry values,
    service startup types and scheduled-task states. Machine scope is checked from any
    elevated session; the current user's own HKCU declarations, including HKCU policy
    keys, are checked as well, so run it from the account whose settings you care about.

    Nothing is changed. Re-run an AtlasDesktop launcher to re-apply a drifted toggle;
    review drifted install tweaks individually. Reapply does not rerun one-time tweaks.
.PARAMETER Json
    Writes the report as JSON to standard output instead of text.
.NOTES
    Exit codes: 0 no drift, 1 drift found, 2 Atlas is not installed or the check failed.
#>
[CmdletBinding()]
param(
    [switch]$Json
)

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($PSScriptRoot))
$bootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($bootstrap)) {
    throw "The PowerShell bootstrap is missing at '$bootstrap'."
}
. $bootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Get-AtlasHealthReport {
    <#
    .SYNOPSIS
        Builds the report object: install facts from the state document plus the drift
        of every recorded toggle state, every tweak category and the given Standalone
        tweaks.
    #>
    param(
        [Parameter(Mandatory = $true)]$Context,
        [Parameter(Mandatory = $true)]$Document,
        [Parameter(Mandatory = $true)][string[]]$Categories,
        [string[]]$StandaloneTweakPaths = @()
    )

    $toggleDrift = @(Test-AtlasToggleDrift -Scope Machine, User)
    $recordedToggleStates = Get-AtlasToggleStateRecords
    $tweakDrift = @()
    foreach ($category in $Categories) {
        $tweakDrift += @(Test-AtlasTweakCategory -Name $category -RegistryScope Machine -Context $Context -RecordedToggleStates $recordedToggleStates)
        $tweakDrift += @(Test-AtlasTweakCategory -Name $category -RegistryScope ProtectedCurrentUser -Context $Context -RecordedToggleStates $recordedToggleStates)
        $tweakDrift += @(Test-AtlasTweakCategory -Name $category -RegistryScope CurrentUser -Context $Context -RecordedToggleStates $recordedToggleStates)
    }
    # Standalone tweaks cannot declare live-user entries, so machine scope covers them.
    foreach ($path in $StandaloneTweakPaths) {
        $tweakDrift += @(Test-AtlasTweak -Path $path -RegistryScope Machine -Context $Context -RecordedToggleStates $recordedToggleStates)
    }

    return [pscustomobject][ordered]@{
        installedVersion = $Document.installedVersion
        installedAt      = $Document.installedAt
        mode             = $Document.mode
        options          = @($Document.options)
        history          = @($Document.history)
        windowsBuild     = $Context.WindowsBuild
        toggles          = $Document.toggles
        toggleDrift      = $toggleDrift
        tweakDrift       = $tweakDrift
        healthy          = ($toggleDrift.Count -eq 0 -and $tweakDrift.Count -eq 0)
    }
}

function Get-AtlasHealthStandaloneTweakPath {
    <#
    .SYNOPSIS
        Returns the files of the manifest's Standalone tweaks that an install plan for
        this machine ran.
    #>
    param(
        [Parameter(Mandatory = $true)]$Context,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$TweaksRoot
    )

    # Reach them from the context, not the document's mode: a Reapply records its own
    # mode, which no plan step names, and an earlier update in the history makes this
    # an upgraded machine.
    $parentMode = if ($Context.IsUpgrade) { 'Upgrade' } else { 'Fresh' }
    foreach ($entry in @($Manifest['Standalone'])) {
        if (@($entry['ParentModes']) -ccontains $parentMode) {
            Join-Path -Path $TweaksRoot -ChildPath (([string]$entry['Slug'] -replace '/', '\') + '.psd1')
        }
    }
}

function Write-AtlasHealthReport {
    param([Parameter(Mandatory = $true)]$Report)

    Write-Host "Atlas $($Report.installedVersion) installed $($Report.installedAt) ($($Report.mode)) on Windows build $($Report.windowsBuild)."
    Write-Host "Options: $(if (@($Report.options).Count) { $Report.options -join ', ' } else { 'none' })"
    $toggleNames = @($Report.toggles.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object)
    Write-Host "Recorded toggles: $($toggleNames.Count)"
    foreach ($name in $toggleNames) {
        Write-Host ("  {0,-36} state {1}" -f $name, $Report.toggles.$name.state)
    }

    if ($Report.healthy) {
        Write-Host ''
        Write-AtlasSuccess -Text 'No drift: every recorded toggle state and applicable tweak still holds.'
        return
    }

    if (@($Report.toggleDrift).Count -gt 0) {
        Write-Host ''
        Write-AtlasWarning -Text "$(@($Report.toggleDrift).Count) recorded toggle state(s) no longer hold:"
        foreach ($item in $Report.toggleDrift) {
            Write-Host "  $($item.Toggle) [$($item.State), $($item.Scope)] $($item.Kind) '$($item.Target)': $($item.Reason)"
        }
    }
    if (@($Report.tweakDrift).Count -gt 0) {
        Write-Host ''
        Write-AtlasWarning -Text "$(@($Report.tweakDrift).Count) install tweak(s) no longer hold:"
        foreach ($item in $Report.tweakDrift) {
            Write-Host "  $($item.Tweak) $($item.Kind) '$($item.Target)': $($item.Reason)"
        }
    }
    Write-Host ''
    Write-AtlasNextStep -Text @(
        'Run the AtlasDesktop launcher of a drifted toggle to apply it again. Review drifted'
        'install tweaks one by one; Reapply does not rerun one-time tweaks.'
    )
}

try {
    foreach ($module in 'Atlas.Core', 'Atlas.State', 'Atlas.Registry', 'Atlas.Toggles', 'Atlas.Tweaks') {
        Import-Module -Name (Join-Path -Path $scriptsRoot -ChildPath "Modules\$module\$module.psd1") -Force -ErrorAction Stop
    }

    $context = Get-AtlasContext -Refresh
    $document = Get-AtlasState -Path $context.StateDocumentPath
    if ($null -eq $document -or [string]::IsNullOrWhiteSpace([string]$document.installedVersion)) {
        [Console]::Error.WriteLine('Atlas is not installed on this machine, or it was installed before the machine state document existed.')
        exit 2
    }

    $tweaksRoot = Join-Path -Path $scriptsRoot -ChildPath 'Tweaks'
    $manifest = Get-AtlasTweakManifest -Path (Join-Path -Path $tweaksRoot -ChildPath 'tweaks.manifest.psd1')
    $categories = @($manifest['Categories'] | ForEach-Object { [string]$_['Name'] })
    $standaloneTweakPaths = @(Get-AtlasHealthStandaloneTweakPath -Context $context -Manifest $manifest -TweaksRoot $tweaksRoot)
    $report = Get-AtlasHealthReport -Context $context -Document $document -Categories $categories `
        -StandaloneTweakPaths $standaloneTweakPaths

    if ($Json) {
        $report | ConvertTo-Json -Depth 8
    }
    else {
        Write-AtlasHealthReport -Report $report
    }
    if ($report.healthy) { exit 0 } else { exit 1 }
}
catch {
    [Console]::Error.WriteLine("[Atlas] $($_.Exception.Message)")
    exit 2
}
