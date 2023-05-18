@echo off
setlocal EnableDelayedExpansion

reg query HKLM\HARDWARE\DESCRIPTION\System /v SystemBiosVersion | find "Hyper-V" > nul 2>&1
if %errorlevel%==0 (
	echo This seems to be Windows running on a Hyper-V guest/virtual machine.
	echo Therefore, Hyper-V won't be disabled in the first place.
	echo]
	echo If you want to use Hyper-V within Hyper-V, enable it like you would normally in Windows.
	echo]
	pause
	exit /b
)	

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

echo Enable Hyper-V features with DISM...
DISM /Online /Enable-Feature:Microsoft-Hyper-V-All /Quiet /NoRestart
if not %errorlevel%==3010 (
	echo]
	echo DISM command may have failed to enable Hyper-V.
	echo If there's no errors above, it's probably already enabled.
)

echo]
echo Setting boot configuration options...
:: Prevents booting if the feature isn't enabled, only for Windows Enterprise
:: bcdedit /set vmslaunchtpye Auto > nul
:: This would be preventing Credential Guard, but it's not really related to Hyper-V
:: bcdedit /deletevalue loadoptions > nul
:: Undocumented
:: bcdedit /deletevalue vm > nul
bcdedit /set hypervisorlaunchtype auto > nul

:enable-drivers
echo]
echo Enabling Hyper-V drivers...
call setSvc.cmd bttflt 0
call setSvc.cmd gencounter 3
call setSvc.cmd hvservice 3
call setSvc.cmd hvsocketcontrol 3
call setSvc.cmd passthruparser 3
call setSvc.cmd pvhdparser 3
call setSvc.cmd spaceparser 3
call setSvc.cmd storflt 0
call setSvc.cmd vhdparser 3
call setSvc.cmd Vid 1
call setSvc.cmd vmbus 0
call setSvc.cmd vmbusr 3
call setSvc.cmd vmgid 3
call setSvc.cmd vpci 0

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
    call setSvc.cmd %%~a 3
)

:: Enable system devices
call toggleDev.cmd /e "*Hyper-V*"

echo Finished, please reboot your device for changes to apply.
pause
exit /b