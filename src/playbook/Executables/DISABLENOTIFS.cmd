@echo off

:: Registry changes
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" /v "Value" /t REG_SZ /d "Deny" /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoCloudApplicationNotification" /t REG_DWORD /d "1" /f > nul

:: Hide Settings pages
for %%a in (
	"notifications"
	"privacy-notifications"
) do (
	call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /hide %%~a /silent
)

:: Disable notif center
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f > nul

:: Disable services
sc config WpnService start=disabled > nul
sc stop WpnService > nul 2>&1
call "%windir%\AtlasModules\Scripts\setSvc.cmd" "WpnUserService" 4
for /f "tokens=5 delims=\" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" ^| find "WpnUserService_"') do (
	call "%windir%\AtlasModules\Scripts\setSvc.cmd" "%%a" 4
	sc stop "%%a" > nul
	sc delete "%%a" > nul
)

echo Disabled notifications.