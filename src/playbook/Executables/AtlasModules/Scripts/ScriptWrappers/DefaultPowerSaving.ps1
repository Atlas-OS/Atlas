#Requires -RunAsAdministrator

Write-Host "Enabling power saving...`n" -ForegroundColor Cyan

# Restore default power schemes
# This should set the power plan to 'Balanced' by default
powercfg /restoredefaultschemes | Out-Null

# Enable power-saving ACPI devices
& toggleDev.cmd -Enable '@("ACPI Processor Aggregator", "Microsoft Windows Management Interface for ACPI")' | Out-Null

# Enable USB device power-saving
foreach ($power_device in (Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi)){
    foreach ($device in @('Win32_USBController', 'Win32_USBControllerDevice', 'Win32_USBHub')) {
        foreach ($hub in Get-WmiObject $device) {
            $pnp_id = $hub.PNPDeviceID
            if ($power_device.InstanceName.ToUpper() -like "*$pnp_id*") {
                $power_device.enable = $True
                $power_device.psbase.put()
            }
        }
    }
}

# Enable device power saving
$keys = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Enum" -Recurse -EA 0
foreach ($value in @(
    "AllowIdleIrpInD3",
    "D3ColdSupported",
    "DeviceSelectiveSuspended",
    "EnableIdlePowerManagement",
    "EnableSelectiveSuspend",
    "EnhancedPowerManagementEnabled",
    "IdleInWorkingState",
    "SelectiveSuspendEnabled",
    "SelectiveSuspendOn",
    "WaitWakeEnabled",
    "WakeEnabled",
    "WdfDirectedPowerTransitionEnable"
)) {
    $oldValue = "$value-OLD"
    $keys | Where-Object { $_.GetValueNames() -contains $oldValue } | ForEach-Object {
        $keyPath = $_.PSPath
        Remove-ItemProperty -Path $keyPath -Name $value
        Rename-ItemProperty -Path $keyPath -Name $oldValue -NewName $value
    }
}

# Set power saving mode for all network cards to default
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" -Name "DefaultPnPCapabilities" -Value 0

# Configure internet adapter settings
$properties = Get-NetAdapter -Physical | Get-NetAdapterAdvancedProperty
foreach ($setting in @(
    # Stands for Ultra Low Power
    "ULPMode",

    # Energy Efficient Ethernet
    "EEE",
    "EEELinkAdvertisement",
    "AdvancedEEE",
    "EnableGreenEthernet",
    "EeePhyEnable",

    # Wi-Fi capability that saves power consumption
    "uAPSDSupport",

    # Self-explanatory
    "EnablePowerManagement",
    "EnableSavePowerNow",
    "bLowPowerEnable",
    "PowerSaveMode",
    "PowerSavingMode",
    "SavePowerNowEnabled",
    "AutoPowerSaveModeEnabled",
    "NicAutoPowerSaver",
    "SelectiveSuspend"
)) {
    $properties | Where-Object { $_.RegistryKeyword -eq "*$setting" -or $_.RegistryKeyword -eq $setting } | Reset-NetAdapterAdvancedProperty
}

# Disable D3 support on SATA/NVMEs while using Modern Standby
# Reference: https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/power-management-for-storage-hardware-devices-intro#d3-support
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Storage" -Name "StorageD3InModernStandby" -ErrorAction SilentlyContinue

# Disable IdlePowerMode for stornvme.sys (storage devices) - the device will never enter a low-power state
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" -Name "IdlePowerMode" -ErrorAction SilentlyContinue

# Reset power throttling to default
# Reference: https://blogs.windows.com/windows-insider/2017/04/18/introducing-power-throttling
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -ErrorAction SilentlyContinue

# Enable the kernel being tickless
# Reference: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#additional-settings
bcdedit /deletevalue disabledynamictick *> $null

# Finish
$null = Read-Host "Completed.`nPress Enter to exit"