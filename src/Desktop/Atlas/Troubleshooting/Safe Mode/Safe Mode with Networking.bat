@echo off
:: Requests admin privleges for people with UAC enabled
fltmc >nul 2>&1 || (
    echo Administrator privileges are required.
    PowerShell -NoProfile Start -Verb RunAs '%0' 2> nul || (
        echo Right-click on the script and select "Run as administrator".
        pause & exit 1
    )
    exit 0
)

bcdedit /set {current} safeboot network
echo Finished, please reboot for changes to apply.
pause