[CmdletBinding()]
param (
    [switch]$Enable,
    [switch]$Silent,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Devices
)

$ErrorActionPreference = 'Stop'

if (-not $Devices -or $Devices.Count -eq 0) {
    throw 'Devices not passed.'
}

$state = if ($Enable) { 'Enabl' } else { 'Disabl' }
$foundDevices = @(Get-PnpDevice -FriendlyName $Devices -ErrorAction SilentlyContinue)

foreach ($device in $foundDevices) {
    try {
        if ($Enable) {
            $device | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
        }
        else {
            $device | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Output ("Something went wrong {0}ing the device: {1}" -f $state, $device)
        Write-Output $_
    }
}

if (-not $Silent) {
    Write-Output ("{0}ed the matched specified devices:" -f $state)
    foreach ($device in $foundDevices.FriendlyName) {
        Write-Output " - $device"
    }
}
