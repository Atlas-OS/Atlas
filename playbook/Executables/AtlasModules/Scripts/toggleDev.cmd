@echo off
set "script=%~dp0Internal\ToggleDevice.ps1"

if not exist "%script%" (
    echo Script not found: "%script%"
    exit /b 1
)

fltmc > nul 2>&1 || (
    echo You need to run this script as an administrator.
    exit /b 1
)

set args=
set "args1=%*"
if defined args1 set "args=%args1:"='%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%script%' %args%"
exit /b %errorlevel%
