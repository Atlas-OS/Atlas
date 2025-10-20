@echo off

if "%~1" == "/silent" goto main

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

:main
:: Disable Bluetooth drivers and services
for %%a in (
	"BluetoothUserService"
	"BTAGService"
	"BthA2dp"
	"BthAvctpSvc"
	"BthEnum"
	"BthHFEnum"
	"BthLEEnum"
	"BthMini"
	"BTHMODEM"
	"BTHPORT"
	"bthserv"
	"BTHUSB"
	"HidBth"
	"Microsoft_Bluetooth_AvrcpTransport"
	"RFCOMM"
) do (
	call "%windir%\AtlasModules\Scripts\setSvc.cmd" %%~a 4
)

:: Seems to not exist sometimes
call "%windir%\AtlasModules\Scripts\setSvc.cmd" BthPan 4 > nul 2>&1

:: Disable Bluetooth devices
call "%windir%\AtlasModules\Scripts\toggleDev.cmd" -Silent '*Bluetooth*'

:: Disable in Send To context menu
call "%windir%\AtlasDesktop\4. Interface Tweaks\Context Menus\Send To\Debloat Send To Context Menu.cmd" -Disable @('Bluetooth')

:: https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-connectivity
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\AllowBluetooth" /v "value" /t REG_DWORD /d "0" /f > nul

if "%~1" == "/silent" exit

echo Finished, please reboot your device for changes to apply.
pause
exit /b
