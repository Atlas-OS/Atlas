@echo off

:: Revert Registry changes
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" /v "Value" /t REG_SZ /d "Allow" /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "1" /f > nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoCloudApplicationNotification" /f > nul 2>&1

:: Unhide Settings pages
for %%a in (
	"notifications"
	"privacy-notifications"
) do (
	call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide %%~a /silent
)

:: Enable services
call "%windir%\AtlasModules\Scripts\setSvc.cmd" "WpnUserService" 2
sc config WpnService start=auto > nul

echo Enabled notifications.