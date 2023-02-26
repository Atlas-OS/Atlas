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

:: https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set

echo Forces the clock to be backed by a platform source, no synthetic timers are allowed.
echo Microsoft says that this should only be used for debugging.
echo]
echo What would you like to do?
echo [1] Set to yes
echo [2] Delete value (default)
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %errorlevel%==1 (
	goto yes
) else (
	goto delete
)

:yes
echo]
bcdedit /set useplatformtick yes > nul
if not %errorlevel%==0 (
	echo Something went wrong doing the BCDEDIT command!
	echo Look at the error above, if there is one.
	pause
	exit /b 1
) else (
	echo Finished, please restart to see the changes.
	pause
	exit /b 0
)

:delete
echo]
bcdedit /deletevalue useplatformtick > nul
if not %errorlevel%==0 (
	echo Something went wrong doing the BCDEDIT command!
	echo Look at the error above, if there is one.
	pause
	exit /b 1
) else (
	echo Finished, please restart to see the changes.
	pause
	exit /b 0
)