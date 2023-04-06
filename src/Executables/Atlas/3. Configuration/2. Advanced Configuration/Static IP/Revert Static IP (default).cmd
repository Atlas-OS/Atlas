@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

for /f "tokens=4" %%a in ('netsh int show interface ^| find "Connected"') do set DeviceName=%%a

:: set dhcp instead of static ip
netsh int ipv4 set address name="%DeviceName%" dhcp
netsh int ipv4 set dnsservers name="%DeviceName%" dhcp
netsh int ipv4 show config "%DeviceName%"

:: enable static ip services (fixes internet icon)
call setSvc,cmd Dhcp 2
call setSvc,cmd netprofm 3
call setSvc,cmd nlasvc 2

echo Finished, please reboot your device for changes to apply.
pause
exit /b