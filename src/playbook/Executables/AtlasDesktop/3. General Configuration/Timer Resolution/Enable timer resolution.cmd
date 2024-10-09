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

echo Before running this, please see the Atlas documentation, linked in the folder.
pause
echo]

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d "1" /f > nul
schtasks /create /tn "Force Timer Resolution" /xml "%windir%\AtlasModules\Other\Force Timer Resolution.xml" /f > nul
schtasks /run /tn "Force Timer Resolution" > nul

echo Finished, please reboot your device for changes to apply.
pause
exit /b