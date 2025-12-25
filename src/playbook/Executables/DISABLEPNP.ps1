# Disable PnP (plug and play) devices
# This is a questionable tweak
# It disables core Plug and Play / ACPI / PCI system devices that Windows relies on to correctly understand and manage the hardware.

$devicePatterns = @(
    "ROOT\KDNIC\*",                             # Microsoft Kernel Debug Network Adapter
    "ROOT\COMPOSITEBUS\*",                      # Composite Bus Enumerator
    "ACPI\PNP0103\*",                           # High precision event timer
    "ACPI\PNP0B00\*",                           # System CMOS/real time clock
    "ACPI\PNP0800\*",                           # System Speaker
    "ACPI\PNP0100\*",                           # System Timer
    "ACPI\PNP0200\*",                           # Direct memory access controller
    "ACPI\PNP0C02\*",                           # Motherboard resources (multiple instances)
    "ACPI\INT0800\*",                           # Legacy device (Intel)
    "ACPI\PNP0C04\*"                            # Numeric Data Processor
)

$deviceNames = @(
    "AMD PSP*",                                 # AMD
    "AMD SMBus",                                # AMD
    "Intel*Management Engine*",                 # Intel
    "Intel*SMBus",								# Intel
    "Base System Device",						# Intel
    "PCI Data Acquisition and Signal Processing Controller", # Intel
    "PCI Encryption/Decryption Controller",				     # Intel
    "PCI Memory Controller",                                 # Intel
    "PCI Simple Communications Controller",                  # Intel
    "PCI standard RAM Controller",                           # Intel
    "SM Bus Controller"                                      # Intel
)

# Disable devices by InstanceId pattern
# No errors as some devices may not have an option to be disabled
foreach ($pattern in $devicePatterns) {
    Get-PnpDevice | Where-Object { $_.InstanceId -like $pattern } |
    Disable-PnpDevice -Confirm:$false -ErrorAction Ignore
}

# Disable devices by FriendlyName
# No errors as some devices may not have an option to be disabled
foreach ($name in $deviceNames) {
    Get-PnpDevice | Where-Object { $_.FriendlyName -like $name } |
    Disable-PnpDevice -Confirm:$false -ErrorAction Ignore
}
