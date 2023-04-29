@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Do not disable Workstation, as it is a dependency of many other features
call setSvc.cmd FontCache 4
call setSvc.cmd Qwave 4
call setSvc.cmd QwaveDrv 4

echo Finished, please reboot your device for changes to apply.
pause
exit /b