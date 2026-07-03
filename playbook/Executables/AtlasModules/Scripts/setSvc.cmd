@echo off
set "script=%~dp0Internal\SetServiceStartup.ps1"

if not exist "%script%" (
    echo Script not found: "%script%"
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%script%" -Name "%~1" -Start "%~2"
exit /b %errorlevel%
