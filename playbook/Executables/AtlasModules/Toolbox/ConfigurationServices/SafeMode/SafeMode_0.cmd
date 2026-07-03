@echo off

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

bcdedit /deletevalue {current} safeboot > nul 2>&1
bcdedit /deletevalue {current} safebootalternateshell > nul 2>&1

echo Finished, please reboot your device for changes to apply.
pause
exit /b