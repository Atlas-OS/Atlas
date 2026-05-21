@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=RecentItems"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=1"
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
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

:: End of state and path update

echo Unlocking recent items...

(
    rem Policy
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInstrumentation" /f > nul
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "ClearRecentDocsOnExit" /f > nul
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /f > nul
    reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoRemoteDestinations" /f > nul
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoStartMenuMFUprogramsList" /f > nul
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /f > nul
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "ShowOrHideMostUsedApps" /f > nul
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /f > nul
    rem Non-policy
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d "1" /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "1" /f

    if /I not "%~2"=="/noAction" (
        taskkill /f /im explorer.exe
        start explorer.exe
        taskkill /f /im SettingsApp.exe
    )
) > nul

call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide privacy-general
if "%~1"=="/silent" exit /b

echo]
echo Finished, you should be able to configure features relating to app, document, etc tracking.
echo See File Explorer's options panel, as well as the Start and general privacy settings pages.
echo Press any key to exit...
pause > nul
exit /b
