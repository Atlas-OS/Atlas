@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

echo Applications like Microsoft Store and Spotify may not function correctly when Wi-Fi is disabled. If this is a problem, enable Wi-Fi and restart the computer.
call setSvc.cmd WlanSvc 4
call setSvc.cmd vwififlt 4

echo]
set /P c="Would you like to disable the network icon? (disables two extra services) [Y/N]: "
if /I "!c!" == "N" goto wifiDskip
call setSvc.cmd netprofm 4
call setSvc.cmd NlaSvc 4

:wifiDskip
echo Finished, please reboot your device for changes to apply.
pause
exit /b