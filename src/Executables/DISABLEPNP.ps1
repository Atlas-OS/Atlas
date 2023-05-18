# Disable PnP (plug and play) devices
$devices = @(
    "AMD PSP",
    "AMD SMBus",
    "Base System Device",
    "*Bluetooth*",
    "Composite Bus Enumerator",
    "Direct memory access controller"
    "High precision event timer",
    "Intel Management Engine",
    "Intel SMBus",
    "Legacy device"
    "Microsoft Kernel Debug Network Adapter",
    "Microsoft RRAS Root Enumerator",
    "Motherboard resources",
    "NDIS Virtual Network Adapter Enumerator",
    "Numeric Data Processor",
    "PCI Data Acquisition and Signal Processing Controller",
    "PCI Encryption/Decryption Controller",
    "PCI Memory Controller",
    "PCI Simple Communications Controller",
    "PCI standard RAM Controller"
    # "Remote Desktop Device Redirector Bus",
    "SM Bus Controller",
    "System CMOS/real time clock",
    "System Speaker",
    "System Timer",
    "UMBus Root Bus Enumerator"
    "Unknown Device"
    "WAN Miniport*"
)

# Don't disable Hyper-V devices on Hyper-V guests
if (!(Get-ItemProperty hklm:\HARDWARE\DESCRIPTION\System -Name SystemBiosVersion | Select-Object -ExpandProperty SystemBiosVersion | Select-String -Quiet "Hyper-V")) {
	$devices = $devices + '*HyperV*'
}

# No errors as some devices may not have an option to be disabled
Get-PnpDevice -FriendlyName $devices -ErrorAction Ignore | Disable-PnpDevice -Confirm:$false -ErrorAction Ignore