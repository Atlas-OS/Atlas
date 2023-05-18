@echo off
setlocal EnableDelayedExpansion

reg query HKLM\HARDWARE\DESCRIPTION\System /v SystemBiosVersion | find "Hyper-V" > nul 2>&1
if %errorlevel%==0 (
	echo You can't run this script, as your Windows installation is a Hyper-V guest/virtual machine.
	echo]
	pause
	exit /b
)	

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

echo Disabling Hyper-V features using DISM...
DISM /Online /Disable-Feature:Microsoft-Hyper-V-All /Quiet /NoRestart
if not %errorlevel%==3010 (
	echo]
	echo DISM command may have failed to enable Hyper-V.
	echo If there's no errors above, it's probably already disabled.
)

echo]
echo Setting boot configuration options...
bcdedit /set hypervisorlaunchtype off > nul
:: bcdedit /set loadoptions DISABLE-LSA-ISO,DISABLE-VBS > nul
:: bcdedit /set vm no > nul
:: Only for Windows Enterprise
:: bcdedit /set vsmlaunchtype Off > nul

echo]
echo Disable drivers and services...
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

echo]
echo Disable system devices...
call toggleDev.cmd "*Hyper-V*"

echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b