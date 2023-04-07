@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

echo This may break some features:
echo - CapFrameX
echo - Network menu/icon
echo If you experience random issues, please enable Event Log again.
call setSvc.cmd EventLog 4

echo Finished, please reboot your device for changes to apply.
pause
exit /b