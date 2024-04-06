@echo off

if "%~1" == "/justuserservice" goto main

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

:main
call "%windir%\AtlasModules\Scripts\setSvc.cmd" "WpnUserService" 2
for /f "tokens=6 delims=[.] " %%a in ('ver') do (if %%a GEQ 22000 call :enablecenter)
if "%~1" == "/justuserservice" exit /b

sc config WpnService start=auto > nul

call :enablecenter
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" /v "Value" /t REG_SZ /d "Allow" /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "1" /f > nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoCloudApplicationNotification" /f > nul 2>&1

for %%a in (
	"notifications"
	"privacy-notifications"
) do (
	call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide "%%a" /silent
)

if "%~1" == "/silent" exit /b

taskkill /f /im explorer.exe > nul 2>&1
taskkill /f /im SystemSettings.exe > nul 2>&1
taskkill /f /im ShellExperienceHost.exe > nul 2>&1
start explorer.exe

echo Finished, please reboot your device for changes to apply.
pause
exit /b

:enablecenter
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /f > nul 2>&1
exit /b