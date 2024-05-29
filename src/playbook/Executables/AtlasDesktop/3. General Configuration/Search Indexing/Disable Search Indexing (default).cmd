@echo off
setlocal EnableDelayedExpansion

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

sc config WSearch start=disabled > nul
sc stop WSearch > nul 2>&1
call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /hide cortana-windowssearch

echo Finished.
pause
exit /b