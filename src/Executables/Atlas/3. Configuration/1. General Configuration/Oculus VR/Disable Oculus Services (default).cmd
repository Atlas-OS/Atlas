@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

:: Do not disable Workstation, as it is a dependency of many other features
!setSvcScript! QwaveDrv 4
!setSvcScript! Qwave 4
!setSvcScript! FontCache 4

echo Finished, please reboot your device for changes to apply.
pause
exit /b