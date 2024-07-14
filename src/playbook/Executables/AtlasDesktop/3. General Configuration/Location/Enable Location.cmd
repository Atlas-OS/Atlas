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

"%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide privacy-location

if "%~1"=="/silent" exit /b

echo Finished, please reboot your device for changes to apply.
pause
exit /b