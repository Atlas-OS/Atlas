@echo off
set "script=%~dp0Internal\PrepareSetting.ps1"

if not exist "%script%" (
    echo Script not found: "%script%"
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%script%" -SettingName "%~1" -StateValue "%~2" -ScriptPath "%~3" -ScriptArgs "%~4"
exit /b %errorlevel%
