@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=NVidiaDisplayContainerContextMenu"
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
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

if not "%~1"=="/silent" call "%windir%\AtlasModules\Scripts\serviceWarning.cmd" %*

:: check if the service exists
reg query "HKCR\DesktopBackground\shell\NVIDIAContainer" > nul 2>&1 || (
    echo The context menu does not exist, thus you cannot continue.
	if "%~1"=="/silent" exit /b
    echo]
    pause
    exit /b 1
)

echo Explorer will be restarted to ensure that the context menu is removed.
pause

:main
reg delete "HKCR\DesktopBackground\Shell\NVIDIAContainer" /f > nul 2>&1

:: delete icon exe
taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe

if "%~1"=="/silent" exit /b

echo Finished, changes have been applied.
pause
exit /b