@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=RecentItems"
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

echo Disabling recent items...

(
    rem Policy
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInstrumentation" /t REG_DWORD /d "1" /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "ClearRecentDocsOnExit" /t REG_DWORD /d "1" /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /t REG_DWORD /d "1" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoRemoteDestinations" /t REG_DWORD /d "1" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoStartMenuMFUprogramsList" /t REG_DWORD /d "1" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /t REG_DWORD /d "1" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "ShowOrHideMostUsedApps" /t REG_DWORD /d "1" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d "1" /f

    rem Non-policy
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d "0" /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f
) > nul

(
    taskkill /f /im SettingsApp.exe
    taskkill /f /im explorer.exe
    start explorer.exe
) > nul 2>&1

call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /hide privacy-general

echo]
echo Finished, features relating to app, document, etc tracking have been disabled.
echo Press any key to exit...
pause > nul
exit /b