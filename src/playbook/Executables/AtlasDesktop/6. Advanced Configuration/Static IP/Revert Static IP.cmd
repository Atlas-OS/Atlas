@echo off

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
		echo You must run this script as admin.
		if "%*"=="" pause
		exit /b 1
	)
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