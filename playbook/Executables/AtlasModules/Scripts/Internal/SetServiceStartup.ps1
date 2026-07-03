# Thin forwarder kept for its callers (setSvc.cmd, Internal\Notifications.ps1 and the
# Printing toggle); the logic lives in the Atlas.Services module
# (Set-AtlasServiceStartup). Exit codes: 0 = success, 1 = missing service or failure
# (preserved from the original script's contract).
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 4)]
    [int]$Start
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Name)) {
    Write-Error -Message 'error: you need to run this with a service/driver to disable.' -ErrorAction Continue
    exit 1
}

$servicePath = Join-Path -Path 'HKLM:\SYSTEM\CurrentControlSet\Services' -ChildPath $Name
if (-not (Test-Path -LiteralPath $servicePath)) {
    Write-Error -Message "error: the specified service/driver ($Name) was not found." -ErrorAction Continue
    exit 1
}

try {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Modules\Atlas.Services\Atlas.Services.psd1')
    Set-AtlasServiceStartup -Name $Name -StartupType $Start
}
catch {
    Write-Error -Message "error: failed to set service $Name with start value $Start. $_" -ErrorAction Continue
    exit 1
}
