# Thin forwarder kept for its callers (setSvc.cmd and the Printing toggle); the logic lives
# in the Atlas.Services module
# (Set-AtlasServiceStartup). Missing services fail by default; reviewed edition/build/
# hardware-optional callers must pass -AllowMissing explicitly. Mutation/import failures
# always exit nonzero.
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 4)]
    [int]$Start,

    [switch]$AllowMissing
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Name)) {
    Write-Error -Message 'error: you need to run this with a service/driver to disable.' -ErrorAction Continue
    exit 1
}

try {
    $servicesManifest = Join-Path -Path $PSScriptRoot `
        -ChildPath '..\Modules\Atlas.Services\Atlas.Services.psd1'
    Import-Module -Name $servicesManifest -Force -ErrorAction Stop
    Set-AtlasServiceStartup -Name $Name -StartupType $Start -AllowMissing:$AllowMissing
}
catch {
    Write-Error -Message "error: failed to set service $Name with start value $Start. $_" -ErrorAction Continue
    exit 1
}
