@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

bcdedit /set {current} safeboot network

echo Finished, please reboot your device for changes to apply.
pause
exit /b