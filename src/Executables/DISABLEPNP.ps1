# Disables PnP (plug and play) devices

$devices = @(
    'ACPI Processor Aggregator',
    'Microsoft Windows Management Interface for ACPI',
    'AMD PSP',
    'AMD SMBus',
    'Base System Device',
    '*Bluetooth*',
    'Composite Bus Enumerator',
    'High precision event timer',
    'Intel Management Engine',
    'Intel SMBus',
    '*Hyper-V*',
    'Microsoft Kernel Debug Network Adapter',
    'Microsoft RRAS Root Enumerator',
    'Motherboard resources',
    'NDIS Virtual Network Adapter Enumerator',
    'Numeric Data Processor',
    'PCI Data Acquisition and Signal Processing Controller',
    'PCI Encryption/Decryption Controller',
    'PCI Memory Controller',
    'PCI Simple Communications Controller',
    'SM Bus Controller',
    'System CMOS/real time clock',
    'System Speaker',
    'System Timer',
    'UMBus Root Bus Enumerator'
)

# No errors as some devices may not have an option to be disabled
Get-PnpDevice -FriendlyName $devices -ErrorAction Ignore | Disable-PnpDevice -Confirm:$false -ErrorAction Ignore