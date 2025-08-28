@echo off
set "script=%windir%\AtlasModules\Scripts\newUsers.ps1"

if not exist "%script%" (
    echo Script not found: "%script%"
    pause
    exit /b 1
)

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
    call RunAsTI.cmd "%~f0" %*
    exit /b
)

powershell -ExecutionPolicy Bypass -NoProfile -File "%script%"

pause
shutdown.exe /F /R /T 2
