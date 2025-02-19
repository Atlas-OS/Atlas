@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=Bluetooth"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=1"
set "scriptPath=%~f0"

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

:: Update Registry (State and Path)
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

if not "%~1"=="/silent" call "%windir%\AtlasModules\Scripts\serviceWarning.cmd" %*

:main
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

if "%~1"=="/silent" exit /b

choice /c:yn /n /m "Would you like to enable the 'Bluetooth File Transfer' Send To context menu entry? [Y/N] "
if %ERRORLEVEL% == 1 call "%windir%\AtlasDesktop\4. Interface Tweaks\Context Menus\Send To\Debloat Send To Context Menu.cmd" -Enable @('Bluetooth')
if %ERRORLEVEL% == 2 call "%windir%\AtlasDesktop\4. Interface Tweaks\Context Menus\Send To\Debloat Send To Context Menu.cmd" -Disable @('Bluetooth')

echo Finished, please reboot your device for changes to apply.
pause
exit /b