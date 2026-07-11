# Thin forwarder kept for its callers (setSvc.cmd, Internal\Set-NotificationState.ps1 and the
# Printing toggle); the logic lives in the Atlas.Services module
# (Set-AtlasServiceStartup). Missing edition-specific services are a successful no-op;
# malformed input or module/import failures exit nonzero.
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 4)]
    [int]$Start
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
    Set-AtlasServiceStartup -Name $Name -StartupType $Start
}
catch {
    Write-Error -Message "error: failed to set service $Name with start value $Start. $_" -ErrorAction Continue
    exit 1
}
