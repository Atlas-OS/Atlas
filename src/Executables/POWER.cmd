@echo off
setlocal EnableDelayedExpansion

:: Detect if user uses laptop device or personal computer
for /f "delims=:{}" %%a in ('wmic path Win32_SystemEnclosure get ChassisTypes ^| findstr [0-9]') do set "CHASSIS=%%a"
for %%a in (8 9 10 11 12 13 14 18 21 30 31 32) do if "!CHASSIS!" == "%%a" (set "DEVICE_TYPE=LAPTOP") else (set "DEVICE_TYPE=PC")

:: Disable Hibernation and Fast Startup
powercfg -h off

:: Disable Modern Standby
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "PlatformAoAcOverride" /t REG_DWORD /d "0" /f

:: Disable SleepStudy (UserNotPresentSession.etl)
wevtutil set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false
wevtutil set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false
wevtutil set-log "Microsoft-Windows-UserModePowerService/Diagnostic" /e:false

if "!DEVICE_TYPE!" == "PC" (
    rem Duplicate High Performance power scheme, customize it and make it the Atlas power scheme
    powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 11111111-1111-1111-1111-111111111111
    powercfg -setactive 11111111-1111-1111-1111-111111111111

    rem Set current power scheme to Atlas
    powercfg -changename scheme_current "Atlas Power Scheme" "Power scheme optimized for optimal latency and performance."
    rem Turn off hard disk after - 0 seconds
    powercfg -setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
    rem Secondary NVMe Idle Timeout - 0 miliseconds
    powercfg -setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 d3d55efd-c1ff-424e-9dc3-441be7833010 0
    rem Primary NVMe Idle Timeout - 0 miliseconds
    powercfg -setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 0
    rem NVME NOPPME - Off
    powercfg -setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 fc7372b6-ab2d-43ee-8797-15e9841f2cca 0
    rem Slide show - Paused
    powercfg -setacvalueindex scheme_current 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1
    rem Allow Away Mode Policy - No
    powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0
    rem System unattended sleep timeout - 0 seconds
    powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 0
    rem Allow hybrid sleep - Off
    powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
    rem Allow Standby States - Off
    powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0
    rem Allow wake timers - Disable
    powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 0
    rem Hub Selective Suspend Timeout - 0 miliseconds
    powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0
    rem USB selective suspend setting - Disabled
    powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    rem USB 3 Link Power Mangement - Off
    powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0
    rem Deep Sleep Enabled/Disabled - Deep Sleep Disabled
    powercfg -setacvalueindex scheme_current 2e601130-5351-4d9d-8e04-252966bad054 d502f7ee-1dc7-4efd-a55d-f04b6f5c0545 0
    rem Allow Throttle States - Off
    powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb 0
    rem Processor performance autonomous mode - Disabled
    powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 8baa4a8a-14c6-4451-8e8b-14bdbd197537 0
    rem Processor autonomous activity window - 0 microseconds
    powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 cfeda3d0-7697-4566-a922-a9086cd49dfa 0
    rem Dim display after - 0 seconds
    powercfg -setacvalueindex scheme_current 7516b95f-f776-4464-8c53-06167f40cc99 17aaa29b-8b43-4b94-aafe-35f64daaf1ee 0
    rem Turn off display after - 0 seconds
    powercfg -setacvalueindex scheme_current 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0

    rem Set the active scheme as the current scheme
    powercfg -setactive scheme_current

    rem Unhide power scheme attributes
    rem Source: https://gist.github.com/Velocet/7ded4cd2f7e8c5fa475b8043b76561b5#file-unlock-powercfg-ps1
    PowerShell -NoP -C "$PowerCfg = (Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings' -Recurse).Name -notmatch '\bDefaultPowerSchemeValues|(\\[0-9]|\b255)$';foreach ($item in $PowerCfg) { Set-ItemProperty -Path $item.Replace('HKEY_LOCAL_MACHINE','HKLM:') -Name 'Attributes' -Value 0 -Force}"

    rem Disable Advanced Configuration and Power Interface (ACPI) devices
    call toggleDev.cmd "ACPI Processor Aggregator" "Microsoft Windows Management Interface for ACPI"

    rem Disable driver power saving
    PowerShell -NoP -C "$usb_devices = @('Win32_USBController', 'Win32_USBControllerDevice', 'Win32_USBHub'); $power_device_enable = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi; foreach ($power_device in $power_device_enable){$instance_name = $power_device.InstanceName.ToUpper(); foreach ($device in $usb_devices){foreach ($hub in Get-WmiObject $device){$pnp_id = $hub.PNPDeviceID; if ($instance_name -like \"*$pnp_id*\"){$power_device.enable = $False; $power_device.psbase.put()}}}}"

    rem Disable power throttling
    rem https://blogs.windows.com/windows-insider/2017/04/18/introducing-power-throttling
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f
)