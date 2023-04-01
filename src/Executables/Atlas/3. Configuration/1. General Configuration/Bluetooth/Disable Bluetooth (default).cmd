@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

:: Disable Bluetooth drivers and services
!setSvcScript! BluetoothUserService 4
!setSvcScript! BTAGService 4
!setSvcScript! BthA2dp 4
!setSvcScript! BthAvctpSvc 4
!setSvcScript! BthEnum 4
!setSvcScript! BthHFEnum 4
!setSvcScript! BthLEEnum 4
!setSvcScript! BthMini 4
!setSvcScript! BTHMODEM 4
!setSvcScript! BthPan 4
!setSvcScript! BTHPORT 4
!setSvcScript! bthserv 4
!setSvcScript! BTHUSB 4
!setSvcScript! HidBth 4
!setSvcScript! Microsoft_Bluetooth_AvrcpTransport 4
!setSvcScript! RFCOMM 4

:: Disable Bluetooth devices
DevManView.exe /disable "*Bluetooth*" /use_wildcard

attrib +h "%appdata%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"

echo Finished, please reboot your device for changes to apply.
pause
exit /b