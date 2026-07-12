[CmdletBinding()]
param (
    [switch]$Enable,
    [switch]$Silent,
    [switch]$AllowNoMatch,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Devices
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (-not $Devices -or $Devices.Count -eq 0) {
    throw 'Devices not passed.'
}
foreach ($pattern in $Devices) {
    if ([string]::IsNullOrWhiteSpace($pattern) -or
        $pattern.Length -gt 256 -or
        $pattern.IndexOf([char]0) -ge 0) {
        throw 'Every device-friendly-name pattern must be nonempty and at most 256 characters.'
    }
}

$state = if ($Enable) { 'Enabl' } else { 'Disabl' }
$pnpModulePath = Join-Path -Path ([Environment]::GetFolderPath('System')) `
    -ChildPath 'WindowsPowerShell\v1.0\Modules\PnpDevice\PnpDevice.psd1'
if (-not [IO.File]::Exists($pnpModulePath)) {
    throw "The inbox PnpDevice module is missing at '$pnpModulePath'."
}
Microsoft.PowerShell.Core\Import-Module -Name $pnpModulePath -Force -ErrorAction Stop

# Enumerate once with Stop semantics, then apply the caller's friendly-name patterns
# locally. Get-PnpDevice -FriendlyName reports no-match and provider failures through
# the same error stream; treating an empty, successful enumeration separately keeps an
# explicit AllowNoMatch from concealing provider/RPC failures.
$allDevices = @(PnpDevice\Get-PnpDevice -PresentOnly -ErrorAction Stop)
$foundDevices = @($allDevices | Where-Object {
        $friendlyName = [string]$_.FriendlyName
        if ([string]::IsNullOrWhiteSpace($friendlyName)) {
            return $false
        }
        foreach ($pattern in $Devices) {
            if ($friendlyName -like $pattern) {
                return $true
            }
        }
        return $false
    })

if ($foundDevices.Count -eq 0) {
    if ($AllowNoMatch) {
        if (-not $Silent) {
            Write-Output 'No present devices matched the requested friendly-name pattern(s).'
        }
        return
    }
    throw "No present devices matched: $($Devices -join ', ')."
}

foreach ($device in $foundDevices) {
    $instanceId = [string]$device.InstanceId
    if ([string]::IsNullOrWhiteSpace($instanceId) -or
        $instanceId.Length -gt 4096 -or
        $instanceId.IndexOf([char]0) -ge 0) {
        throw "Matched device '$($device.FriendlyName)' has an invalid instance ID."
    }

    $resultCodes = if ($Enable) {
        @(PnpDevice\Enable-PnpDevice -InstanceId $instanceId -Confirm:$false `
                -PassThru -ErrorAction Stop)
    }
    else {
        @(PnpDevice\Disable-PnpDevice -InstanceId $instanceId -Confirm:$false `
                -PassThru -ErrorAction Stop)
    }
    if ($resultCodes.Count -ne 1 -or [int]$resultCodes[0] -ne 0) {
        $renderedResult = if ($resultCodes.Count -eq 0) {
            '<no result>'
        }
        else {
            ($resultCodes | ForEach-Object { [string]$_ }) -join ', '
        }
        throw ("{0}ing device '{1}' ({2}) returned WMI result '{3}'." -f `
                $state,
                [string]$device.FriendlyName,
                $instanceId,
                $renderedResult)
    }
}

if (-not $Silent) {
    Write-Output ("{0}ed the matched specified devices:" -f $state)
    foreach ($friendlyName in @($foundDevices | ForEach-Object { [string]$_.FriendlyName })) {
        Write-Output " - $friendlyName"
    }
}
