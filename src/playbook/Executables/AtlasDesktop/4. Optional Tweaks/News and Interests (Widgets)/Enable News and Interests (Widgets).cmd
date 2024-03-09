@echo off

fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList '/c "%0" %*' 2> nul || (
		echo You must run this script as admin.
		exit /b 1
	)
	exit /b
)

if not exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" call "%windir%\AtlasModules\Scripts\wingetCheck.cmd" /edge

echo]
echo Enabling News and Interests (called Widgets in Windows 11)....

(
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /f
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /f
    reg delete "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /f
    taskkill /f /im explorer.exe
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d "0" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "1" /f
    start explorer.exe
) > nul

timeout /t 2 /nobreak > nul
start ms-settings:taskbar

echo]
echo Finished, you should be able to toggle News and Interests or Widgets in Settings.
echo Press any key to exit...
pause > nul
exit /b