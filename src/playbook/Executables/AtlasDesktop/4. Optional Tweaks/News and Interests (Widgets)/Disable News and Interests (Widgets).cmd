@echo off

fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList '/c "%0" %*' 2> nul || (
		echo You must run this script as admin.
		exit /b 1
	)
	exit /b
)

echo]
echo Disabling News and Interests (called Widgets in Windows 11)....

(
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d "0" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f
    reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "0" /f
    taskkill /f /im explorer.exe
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d "2" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "0" /f
    start explorer.exe
) > nul

echo]
echo Finished, changes have been applied.
echo Press any key to exit...
pause > nul
exit /b