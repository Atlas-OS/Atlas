@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

:: Enable Bluetooth drivers and services
!setSvcScript! BthA2dp 3
!setSvcScript! BthEnum 3
!setSvcScript! BthHFEnum 3
!setSvcScript! BthLEEnum 3
!setSvcScript! BthMini 3
!setSvcScript! BTHMODEM 3
!setSvcScript! BthPan 3
!setSvcScript! BTHPORT 3
!setSvcScript! BTHUSB 3
!setSvcScript! HidBth 3
!setSvcScript! Microsoft_Bluetooth_AvrcpTransport 3
!setSvcScript! RFCOMM 3
!setSvcScript! BluetoothUserService 3
!setSvcScript! BTAGService 3
!setSvcScript! BthAvctpSvc 3
!setSvcScript! bthserv 3

:: Enable Bluetooth devices
ToggleDevices.cmd /e "*Bluetooth*"

choice /c:yn /n /m "Would you like to enable the 'Bluetooth File Transfer' Send To context menu entry? [Y/N] "
if !errorlevel! == 1 attrib -h "%APPDATA%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
if !errorlevel! == 2 attrib +h "%APPDATA%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"

echo Finished, please reboot your device for changes to apply.
pause
exit /b