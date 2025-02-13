@echo off
set "settingName=PowerSaving"
set "stateValue=0"
set "scriptPath=%~f0"
set "script=%windir%\AtlasModules\Scripts\ScriptWrappers\DisablePowerSaving.ps1"

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

if not exist "%script%" (
    echo Script not found.
    echo "%script%"
    pause
    exit /b 1
)

reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

powershell -EP Bypass -NoP -File "%script%" %*

echo.
echo Power Saving has been disabled.
echo Press any key to exit...
pause > nul
exit /b
