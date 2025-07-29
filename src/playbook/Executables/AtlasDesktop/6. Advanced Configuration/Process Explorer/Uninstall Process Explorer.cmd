@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=ProcessExplorer"
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

:: Check if WinGet is functional or not
call "%windir%\AtlasModules\Scripts\wingetCheck.cmd" /silent
if %ERRORLEVEL% NEQ 0 (
    echo info: WinGet is not functional, can't uninstall Process Explorer, reverting other changes anyways...
    goto otherChanges
)

winget uninstall -e --id Microsoft.Sysinternals.ProcessExplorer --force --purge --disable-interactivity --accept-source-agreements -h > nul
if %ERRORLEVEL% NEQ 0 echo info: Process Explorer uninstallation failed, reverting other changes anyways...

:otherChanges
sc config pcw start=boot > nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /f > nul 2>&1
del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Process Explorer.lnk" > nul

:: Check if Task Manager is still broken
taskmgr.exe > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Task Manager is still not working, applying fallback fix...
    
    reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /f > nul
    del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Process Explorer.lnk" > nul
    winget uninstall -e --id Microsoft.Sysinternals.ProcessExplorer --force --purge --disable-interactivity --accept-source-agreements -h > nul 2>&1
    sc config pcw start=boot > nul

    echo Fallback fix applied. Please restart your computer for the changes to take effect.
    pause
)
if "%~1"=="/silent" exit /b
echo Finished, changes have been applied.
pause
exit /b
