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

call setSvc.cmd vwififlt 4
call setSvc.cmd WlanSvc 4

echo Applications like Microsoft Store and Spotify may not function correctly when Wi-Fi is disabled.
echo There might be other issues as well, therefore, we do not recommend it.
pause
echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b