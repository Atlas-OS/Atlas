@echo off
setlocal

if "%~3"=="" (
    echo error: missing required arguments.
    exit /b 1
)

set "settingName=%~1"
set "stateValue=%~2"
set "scriptPath=%~3"
set "scriptArgs=%~4"

if /I "%ATLAS_USER_CONTEXT%"=="1" exit /b 0

set "___args="%scriptPath%" %scriptArgs%"
fltmc > nul 2>&1 || (
    echo Administrator privileges are required.
    powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
        echo You must run this script as admin.
        if "%scriptArgs%"=="" pause
        exit /b 1
    )
    exit /b 1
)

reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul || exit /b 1
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul || exit /b 1

exit /b 0
