@echo off
set "script=%windir%\AtlasModules\Scripts\newUsers.ps1"
FOR /F "tokens=3*" %%A IN ('REG QUERY "HKLM\SOFTWARE\AtlasOS\JustInstalled" /v "WasJustInstalled" 2^>Nul') DO (
    set "wasJustInstalled=%%A"
)
whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
        call RunAsTI.cmd "%~f0" %*
        exit /b
    )
if %wasJustInstalled% == 0x1 (
    if %wasJustInstalled% == 0x1 (
        reg delete "HKLM\SOFTWARE\AtlasOS\JustInstalled" /f
        exit /b 0
    )
)
if not exist %wasJustInsalled% (
    if not exist "%script%" (
    echo Script not found: "%script%"
    pause
    exit /b 1
    )

    powershell -ExecutionPolicy Bypass -NoProfile -File "%script%"

    pause
    exit /b 0
) 
