@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

call setSvc.cmd WSearch 2

echo Finished, please reboot your device for changes to apply.
pause
exit /b