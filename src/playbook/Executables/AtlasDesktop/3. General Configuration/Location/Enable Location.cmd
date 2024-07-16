@echo off

if "%~1"=="/silent" goto :main

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
(
	sc config lfsvc start=demand
	sc config MapsBroker start=auto
) > nul

(
	sc start lfsvc
	sc start MapsBroker
	taskkill /f /im SystemSettings.exe
) > nul 2>&1

call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide privacy-location

if "%~1"=="/silent" exit /b

set key="HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowSearchToUseLocation
choice /c:yn /n /m "Would you like to allow Windows Search to use your location? [Y/N] "
if %errorlevel%==1 reg delete %key% /f > nul
if %errorlevel%==2 reg add %key% /t REG_DWORD /d 0 /f > nul

set key1="HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice"
choice /c:yn /n /m "Would you like to unlock Find My Device functionality? [Y/N] "
if %errorlevel%==1 (
	reg delete %key1% /f > nul
	call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide findmydevice /silent
)
if %errorlevel%==2 (
	reg add %key1% /v AllowFindMyDevice /t REG_DWORD /d 0 /f > nul
	reg add %key1% /v LocationSyncEnabled /t REG_DWORD /d 0 /f > nul
)

echo]
echo Finished.
start ms-settings:privacy-location
pause
exit /b