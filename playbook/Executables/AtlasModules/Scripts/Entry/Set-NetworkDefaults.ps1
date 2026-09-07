<#
.SYNOPSIS
    Toolbox entry for the shared network-default implementation in Atlas.Network.
.DESCRIPTION
    The Toolbox network launchers run this script elevated with the requested mode.
    The AtlasDesktop DefaultAtlasNetwork toggle calls the same module function.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Atlas', 'Windows')]
    [string]$Mode
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$scriptsRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path -Path $scriptsRoot -ChildPath 'Initialize-AtlasPowerShell.ps1')
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') `
    -Force -ErrorAction Stop
Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Network\Atlas.Network.psd1') `
    -Force -ErrorAction Stop

try {
    $result = Set-AtlasNetworkDefaults -Mode $Mode
    if ($Mode -eq 'Atlas') {
        Write-Output ("Applied the Atlas network defaults to {0} network adapter class(es), changing {1} value(s)." -f `
                $result.AdapterClassKeyCount, $result.ChangedValueCount)
    }
    else {
        Write-Output ("Reset the network stack with {0} command(s), removed {1} network device(s) and rescanned for devices." -f `
                $result.NetshCommandCount, $result.RemovedDeviceCount)
    }
}
catch {
    Write-Error -Message ("Network defaults operation failed: {0}" -f $_.Exception.Message) `
        -ErrorAction Continue
    exit 1
}

exit 0
