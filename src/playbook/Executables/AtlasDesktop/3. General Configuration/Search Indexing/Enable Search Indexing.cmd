@echo off
setlocal EnableDelayedExpansion
if "%~1"=="/silent" goto main

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
	sc config WSearch start=auto
	sc start WSearch
) > nul
call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide cortana-windowssearch

if "%~1"=="/silent" exit /b
echo Finished, please reboot your device for changes to apply.
pause
exit /b