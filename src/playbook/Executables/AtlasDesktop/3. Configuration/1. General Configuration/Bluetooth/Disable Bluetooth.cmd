@echo off
setlocal EnableDelayedExpansion

if "%~1"=="/silent" goto main

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
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
	"BthPan"
	"BTHPORT"
	"bthserv"
	"BTHUSB"
	"HidBth"
	"Microsoft_Bluetooth_AvrcpTransport"
	"RFCOMM"
) do (
	rem A full path is required for AME Wizard configuration as of now
	call %windir%\AtlasModules\Scripts\setSvc.cmd %%~a 4
)

:: Disable Bluetooth devices
call toggleDev.cmd -Silent '*Bluetooth*'

attrib +h "!appdata!\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"

if "%~1"=="/silent" exit

echo Finished, please reboot your device for changes to apply.
pause
exit /b
