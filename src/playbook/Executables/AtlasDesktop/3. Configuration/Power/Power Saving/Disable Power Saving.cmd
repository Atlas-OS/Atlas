@echo off

if "%~1" == "/setup" goto main

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call %windir%\AtlasModules\Scripts\RunAsTI.cmd "%~f0" %*
	exit /b
)

:: Detect if user uses laptop device or personal computer
for /f "delims=:{}" %%a in ('wmic path Win32_SystemEnclosure get ChassisTypes ^| findstr [0-9]') do set "CHASSIS=%%a"
set "DEVICE_TYPE=PC"
for %%a in (8 9 10 11 12 13 14 18 21 30 31 32) do if "%CHASSIS%" == "%%a" (set "DEVICE_TYPE=LAPTOP")

if "%DEVICE_TYPE%" == "LAPTOP" (
    echo WARNING: You are on a laptop, disabling power saving features will cause faster battery drainage and increased heat output.
    echo          If you use your laptop on battery, certain power saving features will enable, but not all.
    echo          It's NOT recommended to disable power saving on laptops in general.
    echo]
    timeout /t 2 /nobreak > nul
    echo Press any key to continue anyways...
    pause > nul
) else (
    echo This script will disable many power saving features in Windows for reduced latency and increased performance.
    echo Ensure that you have adequate cooling.
    echo]
    pause
)

cls

:main
:: Duplicate Ultimate Performance power scheme, customize it and make it the Atlas power scheme
powercfg /l | find "Power Scheme GUID: 11111111-1111-1111-1111-111111111111  (Atlas Power Scheme)" > nul || (
    powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 11111111-1111-1111-1111-111111111111 > nul
)
powercfg /setactive 11111111-1111-1111-1111-111111111111

:: Set current power scheme to Atlas
powercfg /changename scheme_current "Atlas Power Scheme" "Power scheme optimized for optimal latency and performance."
:: Secondary NVMe Idle Timeout - 0 miliseconds
powercfg /setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 d3d55efd-c1ff-424e-9dc3-441be7833010 0
:: Primary NVMe Idle Timeout - 0 miliseconds
powercfg /setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 0
:: NVME NOPPME - Off
powercfg /setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 fc7372b6-ab2d-43ee-8797-15e9841f2cca 0
:: Slide show - Paused
powercfg /setacvalueindex scheme_current 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1
:: Allow Away Mode Policy - No
powercfg /setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0
:: System unattended sleep timeout - 0 seconds
powercfg /setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 0
:: Allow wake timers - Important Only
powercfg /setacvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 2
:: Hub Selective Suspend Timeout - 0 miliseconds
powercfg /setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0
:: USB selective suspend - Disabled
powercfg /setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
:: USB 3 Link Power Mangement - Off
powercfg /setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0
:: Allow Throttle States - Off
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb 0
:: Dim display after - 0 seconds
powercfg /setacvalueindex scheme_current 7516b95f-f776-4464-8c53-06167f40cc99 17aaa29b-8b43-4b94-aafe-35f64daaf1ee 0
:: Turn off display after - 0 seconds
powercfg /setacvalueindex scheme_current 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0
:: Increase processor performance time check interval
:: Reduces DPCs, can be set all the way to 5000ms for statically clocked systems
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 200

:: Set the active scheme as the current scheme
powercfg /setactive scheme_current

:: Disable Advanced Configuration and Power Interface (ACPI) devices
call %windir%\AtlasModules\Scripts\toggleDev.cmd @("ACPI Processor Aggregator", "Microsoft Windows Management Interface for ACPI") > nul

:: Disable driver/device power saving
PowerShell -NoP -C "$usb_devices = @('Win32_USBController', 'Win32_USBControllerDevice', 'Win32_USBHub'); $power_device_enable = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi; foreach ($power_device in $power_device_enable){$instance_name = $power_device.InstanceName.ToUpper(); foreach ($device in $usb_devices){foreach ($hub in Get-WmiObject $device){$pnp_id = $hub.PNPDeviceID; if ($instance_name -like \"*$pnp_id*\"){$power_device.enable = $False; $power_device.psbase.put()}}}}" > nul
for %%a in (
    "AllowIdleIrpInD3"
    "D3ColdSupported"
    "DeviceSelectiveSuspended"
    "EnableIdlePowerManagement"
    "EnableSelectiveSuspend"
    "EnhancedPowerManagementEnabled"
    "IdleInWorkingState"
    "SelectiveSuspendEnabled"
    "SelectiveSuspendOn"
    "WaitWakeEnabled"
    "WakeEnabled"
    "WdfDirectedPowerTransitionEnable"
) do (
    for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "%%~a" ^| findstr "HKEY"') do (
        reg add "%%b" /v "%%~a" /t REG_DWORD /d "0" /f > nul
    )
)

:: Disable D3 support on SATA/NVMEs while using Modern Standby
:: https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/power-management-for-storage-hardware-devices-intro#d3-support
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v "StorageD3InModernStandby" /t REG_DWORD /d "0" /f > nul

:: Disable IdlePowerMode for stornvme.sys (storage devices) - the device will never enter a low-power state
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IdlePowerMode" /t REG_DWORD /d "0" /f > nul

:: Disable power throttling
:: https://blogs.windows.com/windows-insider/2017/04/18/introducing-power-throttling
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f > nul

:: Disable the kernel from being tickless
:: It's power saving
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#additional-settings
bcdedit /set disabledynamictick yes > nul

if "%~1" == "/setup" exit

echo Completed.
echo Press any key to exit...
pause > nul
exit /b