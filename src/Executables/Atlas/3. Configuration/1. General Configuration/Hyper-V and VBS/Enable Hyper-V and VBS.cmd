@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

:: Enable Hyper-V with DISM
DISM /Online /Enable-Feature:Microsoft-Hyper-V-All /Quiet /NoRestart

bcdedit /set hypervisorlaunchtype auto > nul 2>&1
bcdedit /deletevalue vm > nul 2>&1
:: Some registry entry causes this to make an install unbootable, need to look into
:: bcdedit /set vsmlaunchtype Auto > nul 2>&1
bcdedit /deletevalue loadoptions > nul 2>&1

:: Apply registry changes
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Windows.DeviceGuard::VirtualizationBasedSecurity
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "RequirePlatformSecurityFeatures" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "HypervisorEnforcedCodeIntegrity" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "HVCIMATRequired" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "LsaCfgFlags" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "ConfigureSystemGuardLaunch" /f

:: Found this to be the default
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequireMicrosoftSignedBootChain" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequirePlatformSecurityFeatures" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "Locked" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Locked" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "WasEnabledBy" /t REG_DWORD /d "1" /f

:: Enable drivers
!setSvcScript! hvservice 3
!setSvcScript! vhdparser 3
!setSvcScript! vmbus 0
!setSvcScript! Vid 1
!setSvcScript! bttflt 0
!setSvcScript! gencounter 3
!setSvcScript! hvsocketcontrol 3
!setSvcScript! passthruparser 3
!setSvcScript! pvhdparser 3
!setSvcScript! spaceparser 3
!setSvcScript! storflt 0
!setSvcScript! vmgid 3
!setSvcScript! vmbusr 3
!setSvcScript! vpci 0

:: Enable services
for %%a in (
	"gcs"
	"hvhost"
	"vmcompute"
	"vmicguestinterface"
	"vmicheartbeat"
	"vmickvpexchange"
	"vmicrdv"
	"vmicshutdown"
	"vmictimesync"
	"vmicvmsession"
	"vmicvss"
) do (
    !setSvcScript! %%~a 3
)

:: Enable system devices
call ToggleDevices.cmd /e "*Hyper-V*"

echo Finished, please reboot your device for changes to apply.
pause
exit /b