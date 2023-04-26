@echo off
setlocal EnableDelayedExpansion

:: Detect if user uses laptop device or personal computer
for /f "delims=:{}" %%a in ('wmic path Win32_SystemEnclosure get ChassisTypes ^| findstr [0-9]') do set "CHASSIS=%%a"
for %%a in (8 9 10 11 12 13 14 18 21 30 31 32) do if "!CHASSIS!" == "%%a" (set "DEVICE_TYPE=LAPTOP") else (set "DEVICE_TYPE=PC")

:: Disable Hibernation and Fast Startup
:: Disabling makes NTFS accessable outside of Windows
powercfg -h off

:: Disable SleepStudy (UserNotPresentSession.etl)
wevtutil set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false
wevtutil set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false
wevtutil set-log "Microsoft-Windows-UserModePowerService/Diagnostic" /e:false

:: Duplicate Ultimate Performance power scheme, customize it and make it the Atlas power scheme
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 11111111-1111-1111-1111-111111111111
powercfg -setactive 11111111-1111-1111-1111-111111111111

:: Set current power scheme to Atlas
powercfg -changename scheme_current "Atlas Power Scheme" "Power scheme optimized for optimal latency and performance."
:: Secondary NVMe Idle Timeout - 0 miliseconds
powercfg -setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 d3d55efd-c1ff-424e-9dc3-441be7833010 0
:: Primary NVMe Idle Timeout - 0 miliseconds
powercfg -setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 0
:: NVME NOPPME - Off
powercfg -setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 fc7372b6-ab2d-43ee-8797-15e9841f2cca 0
:: Slide show - Paused
powercfg -setacvalueindex scheme_current 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1
:: Allow Away Mode Policy - No
powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0
:: System unattended sleep timeout - 0 seconds
powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 0
:: Allow hybrid sleep - Off
powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
:: Allow Standby States - Off
powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0
:: Allow wake timers - Disable
powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 0
:: Hub Selective Suspend Timeout - 0 miliseconds
powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0
:: USB selective suspend setting - Disabled
powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
:: USB 3 Link Power Mangement - Off
powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0
:: Deep Sleep Enabled/Disabled - Deep Sleep Disabled
powercfg -setacvalueindex scheme_current 2e601130-5351-4d9d-8e04-252966bad054 d502f7ee-1dc7-4efd-a55d-f04b6f5c0545 0
:: Allow Throttle States - Off
powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb 0
:: Set PCI Link Power to Off
powercfg -setacvalueindex scheme_current 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
:: Processor performance autonomous mode - Disabled
:: powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 8baa4a8a-14c6-4451-8e8b-14bdbd197537 0
:: Processor autonomous activity window - 0 microseconds
:: powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 cfeda3d0-7697-4566-a922-a9086cd49dfa 0
:: Dim display after - 0 seconds
powercfg -setacvalueindex scheme_current 7516b95f-f776-4464-8c53-06167f40cc99 17aaa29b-8b43-4b94-aafe-35f64daaf1ee 0
:: Turn off display after - 0 seconds
powercfg -setacvalueindex scheme_current 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0

:: Prevents parking of multi-threads (do not confuse it with cores parking)
:: Prefers to use Performance-cores for foreground applications and heavy load situations
:: Credit: Revision Team
PowerShell -NoP -C "$cpu = Get-CimInstance Win32_Processor; $cpuName = $cpu.Name; $cpuGen = [int]($cpuName.Substring(0, 2)); if ($cpuGen -gt 11) { powercfg -setacvalueindex scheme_current sub_processor HETEROPOLICY 0; powercfg -setacvalueindex scheme_current sub_processor SCHEDPOLICY 2; }"

:: Set the active scheme as the current scheme
powercfg -setactive scheme_current
    
if "!DEVICE_TYPE!" == "PC" (
    rem Disable Advanced Configuration and Power Interface (ACPI) devices
    call toggleDev.cmd "ACPI Processor Aggregator" "Microsoft Windows Management Interface for ACPI"

    rem Disable driver power saving
    PowerShell -NoP -C "$usb_devices = @('Win32_USBController', 'Win32_USBControllerDevice', 'Win32_USBHub'); $power_device_enable = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi; foreach ($power_device in $power_device_enable){$instance_name = $power_device.InstanceName.ToUpper(); foreach ($device in $usb_devices){foreach ($hub in Get-WmiObject $device){$pnp_id = $hub.PNPDeviceID; if ($instance_name -like \"*$pnp_id*\"){$power_device.enable = $False; $power_device.psbase.put()}}}}"

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
            reg add "%%b" /v "%%~a" /t REG_DWORD /d "0" /f
        )
    )

    rem Disable D3 support on SATA/NVMEs while using Modern Standby
    rem https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/power-management-for-storage-hardware-devices-intro#d3-support
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v "StorageD3InModernStandby" /t REG_DWORD /d "0" /f

    rem Disable IdlePowerMode for stornvme.sys (storage devices) - the device will never enter a low-power state
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IdlePowerMode" /t REG_DWORD /d "0" /f

    rem Disable power throttling
    rem https://blogs.windows.com/windows-insider/2017/04/18/introducing-power-throttling
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f
)
