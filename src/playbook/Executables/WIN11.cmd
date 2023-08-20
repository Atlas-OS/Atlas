@echo off
setlocal EnableDelayedExpansion

:: Check if user is on Windows 11 and if so, make Windows 11 only changes
for /f "tokens=6 delims=[.] " %%a in ('ver') do (if %%a GEQ 22000 (set win11=true))

if defined win11 (
    rd /s /q "C:\Windows\AtlasDesktop\3. Configuration\4. Optional Tweaks\Volume Flyout" > nul
) else (
    rd /s /q "C:\Windows\AtlasDesktop\3. Configuration\4. Optional Tweaks\File Explorer Customization\Compact View" > nul
    rd /s /q "C:\Windows\AtlasDesktop\3. Configuration\4. Optional Tweaks\Windows 11 Context Menu" > nul
    rd /s /q "C:\Windows\AtlasDesktop\3. Configuration\1. General Configuration\Timer Resolution" > nul
    del /f /q "%windir%\AtlasModules\Tools\TimerResolution.exe" > nul
    exit /b
)

:: Re-enable Action Center on Win11, as it breaks calendar
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /f

:: If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs do not have this key.
for /f "usebackq tokens=2 delims=\" %%a in (`reg query HKU ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
    reg query "HKU\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > nul
	if errorlevel 0 call :USERREG "%%a"
)

exit /b

:USERREG
:: Do not show recommendations for tips, shortcuts, new apps, and more in start menu
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d "0" /f > nul

:: Show more pins in Start menu
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_Layout" /t REG_DWORD /d "1" /f > nul

:: Compact mode in Explorer
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /t REG_DWORD /d "1" /f > nul

:: Put taskbar to the left
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAl" /t REG_DWORD /d "0" /f > nul

:: Do not show account related notifications occasionally in start menu
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_AccountNotifications" /t REG_DWORD /d "0" /f > nul

:: Remove Widgets button from taskbar
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "0" /f > nul

:: Remove Chat button from taskbar
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d "0" /f > nul

:: Do not show the voice typing microphone button
reg add "HKU\%~1\Software\Microsoft\input\Settings" /v "IsVoiceTypingKeyEnabled" /t REG_DWORD /d "0" /f > nul

:: Do not show files from Office.com
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowCloudFilesInQuickAccess" /t REG_DWORD /d "0" /f > nul

:: Restore old Windows 10 context menu
reg add "HKU\%~1\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f > nul