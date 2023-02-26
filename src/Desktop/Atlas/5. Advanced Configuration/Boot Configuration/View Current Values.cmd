@echo off
setlocal ENABLEEXTENSIONS
setlocal DISABLEDELAYEDEXPANSION

fltmc >nul 2>&1 || (
    echo Administrator privileges are required.
    PowerShell -NoProfile Start -Verb RunAs '%0' 2> nul || (
        echo Right-click on the script and select 'Run as administrator'.
        pause & exit 1
    )
    exit 0
)

for /f "skip=3 delims=" %%a in ('bcdedit /enum {current}') do (echo %%a)
echo]
echo Press any key to exit...
pause > nul
exit /b 0