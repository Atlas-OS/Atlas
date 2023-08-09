@echo off
setlocal EnableDelayedExpansion

:: Check for a Windows build and exit if Windows 11 is not installed
for /f "tokens=6 delims=[.] " %%a in ('ver') do (
    if %%a lss 22621 (
        exit /b
    )
)

:: Enable Global Timer Resolution requests
:: https://github.com/amitxv/PC-Tuning/blob/main/docs/research.md#fixing-timing-precision-in-windows-after-the-great-rule-change
:: https://randomascii.wordpress.com/2020/10/04/windows-timer-resolution-the-great-rule-change
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d "1" /f

:: Do not show recommendations for tips, shortcuts, new apps, and more in start menu
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d "0" /f

:: Do not show account related notifications occasionally in start menu
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_AccountNotifications" /t REG_DWORD /d "0" /f

:: Remove Widgets from taskbar
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "0" /f

