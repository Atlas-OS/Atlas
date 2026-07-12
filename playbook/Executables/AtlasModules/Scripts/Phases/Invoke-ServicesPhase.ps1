# Services phase.
# Backs up the default Windows services and applies the scripted feature-specific
# network/search configuration. The committed install plan admits this phase only for
# fresh modes; its post-Commit dispatcher is deliberately ungated and the ordered plan
# enforces applicability. It runs as TrustedInstaller.
# Generic Windows service and driver startup values stay at their OS defaults; optional
# product behavior is configured through documented policy or feature-specific interfaces.

Assert-AtlasPrivilege -TrustedInstaller

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$atlasModulesRoot = Split-Path -Parent $scriptsRoot
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Services\Atlas.Services.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force -ErrorAction Stop

$internalRoot = Join-Path -Path $scriptsRoot -ChildPath 'Internal'
$disableFileSharing = Join-Path -Path $internalRoot -ChildPath 'Disable-FileSharing.ps1'
$setLocation = Join-Path -Path $internalRoot -ChildPath 'Set-AtlasLocationMachineState.ps1'
$setIndexing = Join-Path -Path $internalRoot -ChildPath 'Set-AtlasIndexingMachineState.ps1'

function Invoke-AtlasServicesPhaseToggleStateUpdate {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Location', 'Indexing')]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 2)]
        [int]$State
    )

    Set-AtlasToggleState -Name $Name -State $State
    $recorded = Get-AtlasToggleState -Name $Name
    if ($null -eq $recorded -or
        $null -eq $recorded.PSObject.Properties['State'] -or
        $null -eq $recorded.State -or
        [int]$recorded.State -ne $State) {
        throw "Services phase toggle '$Name' did not record state '$State'."
    }
}

# Back up default Windows services & drivers (kept if a backup already exists)
$backupDirectory = Join-Path -Path $atlasModulesRoot -ChildPath 'Other'
$backupPath = Join-Path -Path $backupDirectory -ChildPath 'winServices.reg'
Export-AtlasServicesBackup -FilePath $backupPath

# Disable File Sharing
if (-not (Test-Path -LiteralPath $disableFileSharing -PathType Leaf)) {
    throw "Required Services phase helper is missing at '$disableFileSharing'."
}
& $disableFileSharing -Silent

# Disable Location and configure Indexing through in-process machine helpers.
# State is written only after each helper returns and is read back before phase progress
# can continue, preserving the public toggle's declarative replay contract.
if (-not (Test-Path -LiteralPath $setLocation -PathType Leaf)) {
    throw "Required Services phase helper is missing at '$setLocation'."
}
& $setLocation -State Disable
Invoke-AtlasServicesPhaseToggleStateUpdate -Name Location -State 0

if (-not (Test-Path -LiteralPath $setIndexing -PathType Leaf)) {
    throw "Required Services phase helper is missing at '$setIndexing'."
}
& $setIndexing -State Minimal
Invoke-AtlasServicesPhaseToggleStateUpdate -Name Indexing -State 1
