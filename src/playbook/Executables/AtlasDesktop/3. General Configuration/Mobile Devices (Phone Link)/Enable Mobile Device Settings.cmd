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

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "NoConnectedUser" /f > nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v "AutoDownload" /t REG_DWORD /d "4" /f > nul
call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide mobile-devices

start ms-settings:mobile-devices

echo Finished, you can now use the mobile device settings to sync your phone.
pause
exit /b