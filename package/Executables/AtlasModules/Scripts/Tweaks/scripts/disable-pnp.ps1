# Companion of disable-pnp.psd1. Both halves are best effort: a binding or device
# Windows won't disable is logged as a warning and the rest are still disabled.
# Each list is filtered here, because a cmdlet filter that matches nothing reports the
# same error as a provider failure.
$ErrorActionPreference = 'Stop'

# Disable the LLDP binding, which home networks rarely use, to cut background usage.
# The File Sharing toggle owns the SMB client, server and discovery bindings, so a
# Rebase keeps a recorded choice to share files.
try {
    $bindings = @(Get-NetAdapterBinding -Name '*' -ErrorAction Stop |
            Where-Object { [string]$_.ComponentID -ceq 'ms_lldp' -and [bool]$_.Enabled })
}
catch {
    $bindings = @()
    Write-AtlasLog -Level Warning -Message "Listing network adapter bindings failed, so LLDP stays enabled: $($_.Exception.Message)" -ErrorRecord $_
}
foreach ($binding in $bindings) {
    try {
        Disable-NetAdapterBinding -Name ([string]$binding.Name) -ComponentID 'ms_lldp' `
            -Confirm:$false -ErrorAction Stop | Out-Null
    }
    catch {
        Write-AtlasLog -Level Warning -Message "Disabling the LLDP binding on adapter '$($binding.Name)' failed: $($_.Exception.Message)" -ErrorRecord $_
    }
}

# Disable PnP devices most users don't need, present or not.
# Chipset and platform devices stay enabled: vendor installers such as AMD's use them
# to detect the platform.
$devices = @(
    'Base System Device',
    'Composite Bus Enumerator',
    'Direct memory access controller',
    'High precision event timer',
    'Intel Management Engine',
    'Intel SMBus',
    'Legacy device',
    'Microsoft Kernel Debug Network Adapter',
    'Numeric Data Processor',
    'PCI Data Acquisition and Signal Processing Controller',
    'PCI Memory Controller',
    'PCI standard RAM Controller',
    'System CMOS/real time clock',
    'System Speaker',
    'System Timer'
)

try {
    $matchedDevices = @(Get-PnpDevice -ErrorAction Stop |
            Where-Object { $devices -contains [string]$_.FriendlyName })
}
catch {
    $matchedDevices = @()
    Write-AtlasLog -Level Warning -Message "Listing Plug and Play devices failed, so none were disabled: $($_.Exception.Message)" -ErrorRecord $_
}
foreach ($device in $matchedDevices) {
    try {
        Disable-PnpDevice -InstanceId ([string]$device.InstanceId) -Confirm:$false -ErrorAction Stop | Out-Null
    }
    catch {
        Write-AtlasLog -Level Warning -Message ("Disabling device '{0}' ({1}) failed: {2}" -f `
                [string]$device.FriendlyName, [string]$device.InstanceId, $_.Exception.Message) -ErrorRecord $_
    }
}
