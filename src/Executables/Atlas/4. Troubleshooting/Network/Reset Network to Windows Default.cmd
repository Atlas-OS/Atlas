@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

netsh int ip reset
netsh winsock reset
for /f "tokens=3* delims=: " %%a in ('pnputil /enum-devices /class Net /connected ^| findstr "Device Description:"') do (
	DevManView.exe /uninstall "%%a %%i"
)
pnputil /scan-devices

echo Finished, please reboot your device for changes to apply.
pause
exit /b