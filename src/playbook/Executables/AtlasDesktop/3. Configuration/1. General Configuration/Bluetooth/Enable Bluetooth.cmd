@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Enable Bluetooth drivers and services
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
	call setSvc.cmd %%~a 3
)

:: Enable Bluetooth devices
call toggleDev.cmd -Silent -Enable '*Bluetooth*'
reg delete "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\AllowBluetooth" /v "value" /f > nul

choice /c:yn /n /m "Would you like to enable the 'Bluetooth File Transfer' Send To context menu entry? [Y/N] "
if !errorlevel! == 1 attrib -h "!appdata!\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
if !errorlevel! == 2 attrib +h "!appdata!\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"

echo Finished, please reboot your device for changes to apply.
pause
exit /b