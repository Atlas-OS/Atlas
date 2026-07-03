@echo off
set "script=%~dp0AtlasModules\Scripts\Internal\Notifications.ps1"

if not exist "%script%" (
    echo Script not found: "%script%"
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%script%" -Mode Enable
exit /b %errorlevel%
