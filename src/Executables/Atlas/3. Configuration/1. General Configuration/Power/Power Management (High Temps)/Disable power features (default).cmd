@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

:: Disable driver power saving
PowerShell -NoP -C "$usb_devices = @('Win32_USBController', 'Win32_USBControllerDevice', 'Win32_USBHub'); $power_device_enable = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi; foreach ($power_device in $power_device_enable){$instance_name = $power_device.InstanceName.ToUpper(); foreach ($device in $usb_devices){foreach ($hub in Get-WmiObject $device){$pnp_id = $hub.PNPDeviceID; if ($instance_name -like \"*$pnp_id*\"){$power_device.enable = $False; $power_device.psbase.put()}}}}"

:: Disable ACPI devices
DevManView.exe /disable "ACPI Processor Aggregator"
DevManView.exe /disable "Microsoft Windows Management Interface for ACPI"

:: Disable power throttling
:: https://blogs.windows.com/windows-insider/2017/04/18/introducing-power-throttling
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f > nul 2>&1

:: set atlas - high performance power scheme
powercfg -setactive 11111111-1111-1111-1111-111111111111 > nul 2>&1

echo Finished, please reboot your device for changes to apply.
pause
exit /b