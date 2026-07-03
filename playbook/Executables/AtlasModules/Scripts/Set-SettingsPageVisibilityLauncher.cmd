@echo off
set "script=%~dp0Internal\Set-SettingsPageVisibility.ps1"

if not exist "%script%" (
    echo Script not found: "%script%"
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%script%" %*
exit /b %errorlevel%
