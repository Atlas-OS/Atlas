@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

echo Applying changes...

for /f "tokens=4" %%a in ('netsh int show interface ^| find "Connected"') do set "DeviceName=%%a"

:: Set DHCP instead of Static IP
netsh int ipv4 set address name="%DeviceName%" dhcp > nul
netsh int ipv4 set dnsservers name="%DeviceName%" dhcp > nul
netsh int ipv4 show config "%DeviceName%" > nul

:: Enable DHCP service
call setSvc.cmd Dhcp 2
sc start Dhcp > nul 2>&1

echo Finished, please reboot your device for changes to apply.
pause
exit /b