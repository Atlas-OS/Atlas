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

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "NoConnectedUser" /t REG_DWORD /d "1" /f > nul
call "%windir%\AtlarModules\Scripts\settingsPages.cmd" /hide mobile-devices

choice /c:yn /n /m "Would you like to remove the 'Phone Link' app? [Y/N] "
if %errorlevel% == 1 powershell -NoP -NonI "Get-AppxPackage -AllUsers Microsoft.YourPhone* | Remove-AppxPackage -AllUsers"

choice /c:yn /n /m "Would you like to disable Store auto-updates? [Y/N] "
if %errorlevel% == 1 reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v "AutoDownload" /t REG_DWORD /d "2" /f > nul
if %errorlevel% == 2 reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v "AutoDownload" /t REG_DWORD /d "4" /f > nul

echo Finished.
pause
exit /b