@echo off

if "%~1" == "/silent" goto main

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

echo This will repair and replace any corrupt Windows components and system files.
echo For general issues, this might be a fix. Note that no components of Atlas is reverted with this.
echo]
pause
cls

:main
set -=----------------------------------------------
echo This might take a while.

echo]
echo %-%
echo Restoring the component store...
echo %-%
dism /online /cleanup-image /restorehealth

echo]
echo %-%
echo Restoring system files...
echo %-%
sfc /scannow

echo]
echo Finished, please reboot your device for changes to apply.
if "%~1" == "/silent" exit /b
pause
exit /b
