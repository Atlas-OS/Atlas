# Atlas.Hardware domain: Plug and Play device state.

function Import-AtlasPnpDeviceModule {
    $pnpModulePath = Join-Path -Path ([Environment]::GetFolderPath('System')) `
        -ChildPath 'WindowsPowerShell\v1.0\Modules\PnpDevice\PnpDevice.psd1'
    if (-not [IO.File]::Exists($pnpModulePath)) {
        throw "The inbox PnpDevice module is missing at '$pnpModulePath'."
    }
    Microsoft.PowerShell.Core\Import-Module -Name $pnpModulePath -Force -ErrorAction Stop
}

function Get-AtlasPresentPnpDevice {
    return @(PnpDevice\Get-PnpDevice -PresentOnly -ErrorAction Stop)
}

function Set-AtlasPnpDeviceState {
    <#
    .SYNOPSIS
        Enables or disables one device instance and returns the provider result codes.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InstanceId,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enable', 'Disable')]
        [string]$State
    )

    if ($State -ceq 'Enable') {
        return @(PnpDevice\Enable-PnpDevice -InstanceId $InstanceId -Confirm:$false `
                -PassThru -ErrorAction Stop)
    }
    return @(PnpDevice\Disable-PnpDevice -InstanceId $InstanceId -Confirm:$false `
            -PassThru -ErrorAction Stop)
}

function Set-AtlasDeviceState {
    <#
    .SYNOPSIS
        Enables or disables every present Plug and Play device whose friendly name
        matches one of the given wildcard patterns. No match is an error unless
        -AllowNoMatch is given; a provider failure is always an error.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enable', 'Disable')]
        [string]$State,

        # Friendly-name wildcard patterns, for example '*Bluetooth*'.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Devices,

        [switch]$AllowNoMatch,

        [switch]$Silent
    )

    foreach ($pattern in $Devices) {
        if ([string]::IsNullOrWhiteSpace($pattern) -or
            $pattern.Length -gt 256 -or
            $pattern.IndexOf([char]0) -ge 0) {
            throw 'Every device-friendly-name pattern must be nonempty and at most 256 characters.'
        }
    }

    $verb = if ($State -ceq 'Enable') { 'Enabl' } else { 'Disabl' }
    Import-AtlasPnpDeviceModule

    # Enumerate once with Stop semantics, then apply the caller's friendly-name patterns
    # locally. Get-PnpDevice -FriendlyName reports no-match and provider failures through
    # the same error stream; treating an empty, successful enumeration separately keeps an
    # explicit AllowNoMatch from concealing provider/RPC failures.
    $allDevices = @(Get-AtlasPresentPnpDevice)
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
            Write-AtlasLog -Message "No present devices matched the requested friendly-name pattern(s): $($Devices -join ', ')."
            if (-not $Silent) {
                Write-AtlasNote -Text 'No matching devices are present on this PC, so there was nothing to change.'
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

        $resultCodes = @(Set-AtlasPnpDeviceState -InstanceId $instanceId -State $State)
        if ($resultCodes.Count -ne 1 -or [int]$resultCodes[0] -ne 0) {
            $renderedResult = if ($resultCodes.Count -eq 0) {
                '<no result>'
            }
            else {
                ($resultCodes | ForEach-Object { [string]$_ }) -join ', '
            }
            throw ("{0}ing device '{1}' ({2}) returned WMI result '{3}'." -f `
                    $verb,
                    [string]$device.FriendlyName,
                    $instanceId,
                    $renderedResult)
        }
    }

    $friendlyNames = @($foundDevices | ForEach-Object { [string]$_.FriendlyName })
    Write-AtlasLog -Message ("{0}ed {1} matched device(s): {2}." -f $verb, $friendlyNames.Count, ($friendlyNames -join ', '))
    if (-not $Silent) {
        Write-AtlasSuccess -Text ("{0}ed {1} device(s):" -f $verb, $friendlyNames.Count)
        Write-AtlasNote -Text ([string[]]@($friendlyNames | ForEach-Object { "  - $_" }))
    }
}
