@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Enable Bluetooth drivers and services
call setSvc.cmd BluetoothUserService 3
call setSvc.cmd BTAGService 3
call setSvc.cmd BthA2dp 3
call setSvc.cmd BthAvctpSvc 3
call setSvc.cmd BthEnum 3
call setSvc.cmd BthHFEnum 3
call setSvc.cmd BthLEEnum 3
call setSvc.cmd BthMini 3
call setSvc.cmd BTHMODEM 3
call setSvc.cmd BthPan 3
call setSvc.cmd BTHPORT 3
call setSvc.cmd bthserv 3
call setSvc.cmd BTHUSB 3
call setSvc.cmd HidBth 3
call setSvc.cmd Microsoft_Bluetooth_AvrcpTransport 3
call setSvc.cmd RFCOMM 3

:: Enable Bluetooth devices
call toggleDev.cmd /e "*Bluetooth*"

choice /c:yn /n /m "Would you like to enable the 'Bluetooth File Transfer' Send To context menu entry? [Y/N] "
if !errorlevel! == 1 attrib -h "%APPDATA%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
if !errorlevel! == 2 attrib +h "%APPDATA%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"

cls & echo Finished, please reboot your device for changes to apply.
pause
exit /b