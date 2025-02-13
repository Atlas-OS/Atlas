@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=SuperFetch"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=0"
set "scriptPath=%~f0"

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

:: Update Registry (State and Path)
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

:: End of state and path update
:main
setlocal EnableDelayedExpansion

:: Remove lower filters for rdyboost driver
set "key=HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}"
for /f "skip=1 tokens=3*" %%a in ('reg query !key! /v "LowerFilters"') do (set val=%%a)
set val=!val:rdyboost\0=!
set val=!val:\0rdyboost=!
set val=!val:rdyboost=!
reg add "!key!" /v "LowerFilters" /t REG_MULTI_SZ /d "!val!" /f > nul

:: Disable ReadyBoost
reg add "HKLM\SYSTEM\CurrentControlSet\Services\rdyboost" /v "Start" /t REG_DWORD /d "4" /f > nul

:: Remove ReadyBoost tab
reg delete "HKCR\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}" /f > nul 2>&1

:: Disable SysMain (Prefetch, Memory Management features)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v "Start" /t REG_DWORD /d "4" /f > nul 

echo Finished, please reboot your device for changes to apply.
pause
exit /b