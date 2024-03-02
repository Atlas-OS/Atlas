@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
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
	"BTHPORT"
	"bthserv"
	"BTHUSB"
	"HidBth"
	"Microsoft_Bluetooth_AvrcpTransport"
	"RFCOMM"
) do (
	call setSvc.cmd %%~a 3
)

:: Seems to not exist sometimes
call setSvc.cmd BthPan 3 > nul 2>&1

:: Enable Bluetooth devices
call toggleDev.cmd -Silent -Enable '*Bluetooth*'

:: https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-connectivity
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\AllowBluetooth" /v "value" /t REG_DWORD /d "2" /f > nul

choice /c:yn /n /m "Would you like to enable the 'Bluetooth File Transfer' Send To context menu entry? [Y/N] "
if %ERRORLEVEL% == 1 call "%windir%\AtlasDesktop\4. Optional Tweaks\Send To Context Menu\Debloat Send To Context Menu.cmd" -Enable @('Bluetooth')
if %ERRORLEVEL% == 2 call "%windir%\AtlasDesktop\4. Optional Tweaks\Send To Context Menu\Debloat Send To Context Menu.cmd" -Disable @('Bluetooth')

echo Finished, please reboot your device for changes to apply.
pause
exit /b