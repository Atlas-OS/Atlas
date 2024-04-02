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

:main
sc config WpnService start=disabled > nul
sc stop WpnService > nul 2>&1

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" /v "Value" /t REG_SZ /d "Deny" /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoCloudApplicationNotification" /t REG_DWORD /d "1" /f > nul

for %%a in (
	"notifications"
	"privacy-notifications"
) do (
	call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /hide %%a /silent
)

if "%~1"=="/silent" (
	call :userservice
	exit /b
) else (
	for /f "tokens=6 delims=[.] " %%a in ('ver') do (
		if %%a LSS 22000 (
			call :userservice
		) else (
			setlocal EnableDelayedExpansion
			echo On Windows 11, disabling the user notification service will prevent you from using the calendar in the taskbar.
			choice /c:yn /n /m "Would you like to disable the user notification service? [Y/N] "
		)
		echo]
	)
)

taskkill /f /im explorer.exe > nul 2>&1
taskkill /f /im SystemSettings.exe > nul 2>&1
taskkill /f /im ShellExperienceHost.exe > nul 2>&1
start explorer.exe

echo Finished.
pause
exit /b

:userservice
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f > nul
call "%windir%\AtlasModules\Scripts\setSvc.cmd" "WpnUserService" 4
for /f "tokens=5 delims=\" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" ^| find "WpnUserService_"') do (
	call "%windir%\AtlasModules\Scripts\setSvc.cmd" "%%a" 4
	sc stop "%%a" > nul
	sc delete "%%a" > nul
)