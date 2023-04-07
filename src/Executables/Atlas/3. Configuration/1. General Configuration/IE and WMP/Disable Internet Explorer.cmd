@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

DISM /Online /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /NoRestart

echo Finished, please reboot your device for changes to apply.
pause
exit /b