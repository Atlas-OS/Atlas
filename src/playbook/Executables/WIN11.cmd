@echo off
setlocal EnableDelayedExpansion

:: Check for a Windows build and make changes
for /f "tokens=6 delims=[.] " %%a in ('ver') do (
    if %%a LSS 22621 (
        for /f "usebackq delims=" %%a in (`dir /b /a:d "C:\Users"`) do (
            rem Delete Windows 11 only tweaks
            del /s /f /q "C:\Users\%%a\Desktop\Atlas\3. Configuration\4. Optional Tweaks\Windows 11 Context Menu"
            del /s /f /q "C:\Users\%%a\Desktop\Atlas\3. Configuration\1. General Configuration\Timer Resolution"
            del /f /q "%windir%\AtlasModules\Tools\TimerResolution.exe"
        )
        exit /b
    )
)

:: Re-enable Action Center on Win11, as it breaks calendar
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /f

for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
	REM If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs do not have this key.
	reg query "HKU\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_"
	if not !errorlevel! == 1 (
		call :USERREG "%%a"
	)
)

:USERREG
:: Do not show recommendations for tips, shortcuts, new apps, and more in start menu
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d "0" /f

:: Show more pins in Start menu
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_Layout" /t REG_DWORD /d "1" /f

:: Put taskbar to the left
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAl" /t REG_DWORD /d "0" /f

:: Do not show account related notifications occasionally in start menu
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_AccountNotifications" /t REG_DWORD /d "0" /f

:: Remove Widgets button from taskbar
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "0" /f

:: Remove Chat button from taskbar
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d "0" /f

:: Do not show the voice typing microphone button
reg add "HKU\%~1\Software\Microsoft\input\Settings" /v "IsVoiceTypingKeyEnabled" /t REG_DWORD /d "0" /f

:: Do not show files from Office.com
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowCloudFilesInQuickAccess" /t REG_DWORD /d "0" /f

:: Restore old Windows 10 context menu
reg add "HKU\%~1\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f