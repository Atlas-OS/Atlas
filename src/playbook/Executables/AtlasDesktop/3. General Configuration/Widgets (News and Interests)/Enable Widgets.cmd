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

call "%windir%\AtlasModules\Scripts\edgeCheck.cmd"
if %errorlevel% neq 0 exit /b 1

echo]
echo Enabling News and Interests (called Widgets in Windows 11)...

(
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /f
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /f
    taskkill /f /im explorer.exe
    start explorer.exe
) > nul 2>&1

timeout /t 3 /nobreak > nul
start ms-settings:taskbar

echo]
echo Finished, you should be able to toggle News and Interests or Widgets in Settings.
echo Press any key to exit...
pause > nul
exit /b