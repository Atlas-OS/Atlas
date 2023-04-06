@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

:: Enable device power saving
PowerShell -NoP -C "$usb_devices = @('Win32_USBController', 'Win32_USBControllerDevice', 'Win32_USBHub'); $power_device_enable = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi; foreach ($power_device in $power_device_enable){$instance_name = $power_device.InstanceName.ToUpper(); foreach ($device in $usb_devices){foreach ($hub in Get-WmiObject $device){$pnp_id = $hub.PNPDeviceID; if ($instance_name -like \"*$pnp_id*\"){$power_device.enable = $True; $power_device.psbase.put()}}}}"

:: Enable ACPI devices
call ToggleDevices.cmd /e "ACPI Processor Aggregator" "Microsoft Windows Management Interface for ACPI"

:: Enable power throttling
:: https://blogs.windows.com/windows-insider/2017/04/18/introducing-power-throttling/
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /f > nul 2>&1

choice /c:yn /n /m "Do you want to use Balanced power plan (possibly better temperatures on laptops)? [Y/N]"
if !errorlevel! == 1 goto powerA
if !errorlevel! == 2 goto powerB

:powerA
:: Set Balanced power scheme - for laptops
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e > nul 2>&1
goto finish

:powerB
:: Set Atlas - high performance power scheme
powercfg -setactive 11111111-1111-1111-1111-111111111111 > nul 2>&1
goto finish

:finish
echo Finished, please reboot your device for changes to apply.
pause
exit /b