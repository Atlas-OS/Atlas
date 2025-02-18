@echo off
set "script=%windir%\AtlasModules\Scripts\ScriptWrappers\UpdateDrivers.ps1"

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
    echo Script not found: "%script%"
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -NoProfile -File "%script%"

echo.
pause > null
exit /b 0
