@echo off
setlocal EnableDelayedExpansion

:: Check for a Windows build and make changes
for /f "tokens=6 delims=[.] " %%a in ('ver') do (
    if %%a LSS 22621 (
        rem Hide Win11 Context Menu folder
        for /f "usebackq delims=" %%a in (`dir /b /a:d "C:\Users"`) do (
            attrib +s +h "C:\Users\%%a\Desktop\Atlas\3. Configuration\4. Optional Tweaks\Win11 Context Menu"
        )
        exit /b
    )
)

:: Set current user variable to apply HKCU
set "current_user=%windir%\AtlasModules\Tools\NsudoLG.exe -U:C -P:E -Wait"

:: Enable Global Timer Resolution requests
:: https://github.com/amitxv/PC-Tuning/blob/main/docs/research.md#fixing-timing-precision-in-windows-after-the-great-rule-change
:: https://randomascii.wordpress.com/2020/10/04/windows-timer-resolution-the-great-rule-change
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d "1" /f

:: Re-enable action center on Win11, as it breaks calendar
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /f

:: Do not show recommendations for tips, shortcuts, new apps, and more in start menu
%current_user% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d "0" /f

:: Do not show account related notifications occasionally in start menu
%current_user% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_AccountNotifications" /t REG_DWORD /d "0" /f

:: Remove Widgets button from taskbar
%current_user% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "0" /f

:: Remove Chat button from taskbar
%current_user% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d "0" /f

:: Do not show the voice typing microphone button
%current_user% reg add "HKCU\Software\Microsoft\input\Settings" /v "IsVoiceTypingKeyEnabled" /t REG_DWORD /d "0" /f

:: Do not show files from Office.com
%current_user% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowCloudFilesInQuickAccess" /t REG_DWORD /d "0" /f

:: Restore old Windows 10 context menu
%current_user% reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f