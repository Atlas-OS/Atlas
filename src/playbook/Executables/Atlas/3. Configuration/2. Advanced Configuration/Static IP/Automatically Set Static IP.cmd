@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

ping -n 1 -4 www.example.com | find "time=" > nul 2>&1
if !errorlevel! == 1 (
	echo You must have an internet connection to use this script.
	pause
	exit /b 1
)

set /P DNS1="Set primary DNS Server (e.g. 1.1.1.1): "
set /P DNS2="Set alternate DNS Server (e.g. 1.0.0.1): "
for /f "tokens=4" %%a in ('netsh int show interface ^| find "Connected"') do set DeviceName=%%a
for /f "tokens=3" %%a in ('netsh int ip show config name^="!DeviceName!" ^| findstr "IP Address:"') do set LocalIP=%%a
for /f "tokens=3" %%a in ('netsh int ip show config name^="!DeviceName!" ^| findstr "Default Gateway:"') do set DHCPGateway=%%a
for /f "tokens=2 delims=()" %%a in ('netsh int ip show config name^="!DeviceName!" ^| findstr /r "(.*)"') do for %%i in (%%a) do set DHCPSubnetMask=%%i

:: Check for errors and exit if invalid
cls
if "!DeviceName!" == "" set incorrectIP=1
call:isValidIP !LocalIP!
call:isValidIP !DHCPGateway!
call:isValidIP !DHCPSubnetMask!
call:isValidIP !DNS1!
call:isValidIP !DNS2!

if !incorrectIP! == 1 (
	echo Setting a Static IP address failed.
	pause
	exit /b 1
)

:: Set Static IP
netsh int ipv4 set address name="!DeviceName!" static !LocalIP! !DHCPSubnetMask! !DHCPGateway! > nul 2>&1
netsh int ipv4 set dns name="!DeviceName!" static !DNS1! primary > nul 2>&1
netsh int ipv4 add dns name="!DeviceName!" !DNS2! index=2 > nul 2>&1

:: Display details about the connection
echo Interface: !DeviceName!
echo Private IP: !LocalIP!
echo Subnet Mask: !DHCPSubnetMask%!
echo Gateway: !DHCPGateway!
echo Primary DNS: !DNS1!
echo Alternate DNS: !DNS2!
echo.
echo If this information appears to be incorrect or is blank, please report it on Discord or Github.

:: Disable DHCP service, not needed when using Static IP
call setSvc.cmd Dhcp 4

echo Finished, please reboot your device for changes to apply.
pause
exit /b

:isValidIP
:: Credit to Phlegm for error checking
for /f "tokens=1-4 delims=./" %%a in ("%1") do (
	if %%a LSS 1 set incorrectIP=1
	if %%a GTR 255 set incorrectIP=1
	if %%b LSS 0 set incorrectIP=1
	if %%b GTR 255 set incorrecIP=1
	if %%c LSS 0 set incorrectIP=1
	if %%c GTR 255 set incorrectIP=1
	if %%d LSS 0 set incorrectIP=1
	if %%d GTR 255 set incorrectIP=1
)