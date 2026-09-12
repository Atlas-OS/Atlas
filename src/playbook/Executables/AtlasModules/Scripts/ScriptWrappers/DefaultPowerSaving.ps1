#Requires -RunAsAdministrator
param (
    [switch]$Silent
)

$windir = [Environment]::GetFolderPath('Windows')
& "$windir\AtlasModules\initPowerShell.ps1"

Write-Host "`nRestoring default power schemes..." -ForegroundColor Yellow
# This should set the power plan to 'Balanced' by default
powercfg /restoredefaultschemes | Out-Null

Write-Host "Enabling power-saving ACPI devices..." -ForegroundColor Yellow
& toggleDev.cmd -Enable '@("ACPI Processor Aggregator", "Microsoft Windows Management Interface for ACPI")' | Out-Null

Write-Host "Enabling device power-saving..." -ForegroundColor Yellow
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

Write-Host "Enabling network adapter power saving..." -ForegroundColor Yellow
# Set power saving mode for all network cards to default
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" -Name "DefaultPnPCapabilities" -Value 0
# Configure network adapter settings
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
Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI | Set-CimInstance -Property @{ Enable = $true }

Write-Host "Enabling miscellaneous power-saving..." -ForegroundColor Yellow
# Disable D3 support on SATA/NVMEs while using Modern Standby
# Reference: https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/power-management-for-storage-hardware-devices-intro#d3-support
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Storage" -Name "StorageD3InModernStandby" -ErrorAction SilentlyContinue
# Disable IdlePowerMode for stornvme.sys (storage devices) - the device will never enter a low-power state
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" -Name "IdlePowerMode" -ErrorAction SilentlyContinue
# Reset power throttling to default
# Reference: https://blogs.windows.com/windows-insider/2017/04/18/introducing-power-throttling
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -ErrorAction SilentlyContinue


if ($Silent) { exit }
# Finish
Read-Pause "`nCompleted.`nPress Enter to exit"