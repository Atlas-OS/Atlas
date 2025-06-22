@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=StaticIp"
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

:: Exit because the script requires manual text input
if "%~1"=="/silent" exit /b

:: Update Registry (State and Path)
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

if not "%~1"=="/silent" call "%windir%\AtlasModules\Scripts\serviceWarning.cmd" %*

ping -n 1 -4 www.example.com > nul 2>&1 || (
	echo You must have an internet connection to use this script.
	pause
	exit /b 1
)

set /P DNS1="Set primary DNS Server (e.g. 1.1.1.1): " || set DNS1=1.1.1.1
set /P DNS2="Set alternate DNS Server (e.g. 1.0.0.1): " || set DNS2=1.0.0.1
for /f "tokens=*" %%a in ('powershell -NonI -NoP -C "(Get-NetAdapter -Physical | ? { $_.Status -eq 'Up' }).Name"') do set "DeviceName=%%a"
for /f "tokens=3" %%a in ('netsh int ip show config name^="%DeviceName%" ^| findstr "IP Address:"') do set "LocalIP=%%a"
for /f "tokens=3" %%a in ('netsh int ip show config name^="%DeviceName%" ^| findstr "Default Gateway:"') do set "DHCPGateway=%%a"
for /f "tokens=2 delims=()" %%a in ('netsh int ip show config name^="%DeviceName%" ^| findstr /r "(.*)"') do for %%i in (%%a) do set "DHCPSubnetMask=%%i"

:: Check for errors and exit if invalid
echo]
if "%DeviceName%" == "" set "incorrectIP=1"
call :isValidIP %LocalIP%
call :isValidIP %DHCPGateway%
call :isValidIP %DHCPSubnetMask%
call :isValidIP %DNS1%
call :isValidIP %DNS2%

if "%incorrectIP%" == "1" (
	echo Setting a Static IP address failed, as something detected was invalid.
	pause
	exit /b 1
)

:: Display details about the connection
echo ----------------------------
echo Settings to be applied
echo ----------------------------
echo Interface: %DeviceName%
echo Private IP: %LocalIP%
echo Subnet Mask: %DHCPSubnetMask%%
echo Gateway: %DHCPGateway%
echo Primary DNS: %DNS1%
echo Alternate DNS: %DNS2%
echo]
echo If this information appears to be incorrect or is blank, please report it on Discord or GitHub.
echo]
echo Press any key to apply...
pause > nul

:: Set Static IP
netsh int ipv4 set address name="%DeviceName%" static %LocalIP% %DHCPSubnetMask% %DHCPGateway% > nul 2>&1
netsh int ipv4 set dns name="%DeviceName%" static %DNS1% primary > nul 2>&1
netsh int ipv4 add dns name="%DeviceName%" %DNS2% index=2 > nul 2>&1

echo Completed.
pause
exit /b

:isValidIP
:: Credit to Phlegm for error checking
for /f "tokens=1-4 delims=./" %%a in ("%1") do (
	if %%a LSS 1 set "incorrectIP=1"
	if %%a GTR 255 set "incorrectIP=1"
	if %%b LSS 0 set "incorrectIP=1"
	if %%b GTR 255 set "incorrecIP=1"
	if %%c LSS 0 set "incorrectIP=1"
	if %%c GTR 255 set "incorrectIP=1"
	if %%d LSS 0 set "incorrectIP=1"
	if %%d GTR 255 set "incorrectIP=1"
)