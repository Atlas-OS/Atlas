@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Disable Hyper-V using DISM
DISM /Online /Disable-Feature:Microsoft-Hyper-V-All /Quiet /NoRestart

bcdedit /set hypervisorlaunchtype off > nul 2>&1
bcdedit /set vm no > nul 2>&1
bcdedit /set vsmlaunchtype Off > nul 2>&1
bcdedit /set loadoptions DISABLE-LSA-ISO,DISABLE-VBS > nul 2>&1

:: Apply registry changes
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Windows.DeviceGuard::VirtualizationBasedSecurity
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "EnableVirtualizationBasedSecurity" /d "0" /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "RequirePlatformSecurityFeatures" /d "1" /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "HypervisorEnforcedCodeIntegrity" /d "0" /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "HVCIMATRequired" /d "0" /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "LsaCfgFlags" /d "0" /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "ConfigureSystemGuardLaunch" /d "0" /f > nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequireMicrosoftSignedBootChain" /t REG_DWORD /d "0" /f > nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "WasEnabledBy" /t REG_DWORD /d "0" /f > nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f > nul 2>&1

:: Disable drivers and services
for %%a in (
    "bttflt"
    "gcs"
    "gencounter"
    "hvhost"
    "hvservice"
    "hvsocketcontrol"
    "passthruparser"
    "pvhdparser"
    "spaceparser"
    "storflt"
    "vhdparser"
    "Vid"
    "vkrnlintvsc"
    "vkrnlintvsp"
    "vmbus"
    "vmbusr"
    "vmcompute"
    "vmgid"
    "vmicguestinterface"
    "vmicheartbeat"
    "vmickvpexchange"
    "vmicrdv"
    "vmicshutdown"
    "vmictimesync"
    "vmicvmsession"
    "vmicvss"
    "vpci"
) do (
    call setSvc.cmd %%~a 4
)

:: Disable system devices
call toggleDev.cmd "*Hyper-V*"

echo Finished, please reboot your device for changes to apply.
pause
exit /b