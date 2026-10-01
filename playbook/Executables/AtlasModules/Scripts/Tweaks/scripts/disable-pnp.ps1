# Companion of disable-pnp.psd1.
$ErrorActionPreference = 'Stop'

# Disable rarely-needed network adapter bindings to cut background usage.
Get-NetAdapterBinding -Name '*' -ComponentID ms_msclient, ms_server, ms_lldp, ms_lltdio, ms_rspndr -ErrorAction SilentlyContinue |
    Disable-NetAdapterBinding -ErrorAction SilentlyContinue |
    Out-Null

# Disable PnP devices most users don't need.
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

Get-PnpDevice -FriendlyName $devices -ErrorAction SilentlyContinue |
    Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
