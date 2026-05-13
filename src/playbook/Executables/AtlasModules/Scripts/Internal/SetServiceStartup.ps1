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
    Write-Error 'error: you need to run this with a service/driver to disable.'
    exit 1
}

$servicePath = Join-Path -Path 'HKLM:\SYSTEM\CurrentControlSet\Services' -ChildPath $Name
if (-not (Test-Path -LiteralPath $servicePath)) {
    Write-Error "error: the specified service/driver ($Name) was not found."
    exit 1
}

try {
    Set-ItemProperty -LiteralPath $servicePath -Name 'Start' -Value $Start -Type DWord -ErrorAction Stop
}
catch {
    Write-Error "error: failed to set service $Name with start value $Start. $_"
    exit 1
}
