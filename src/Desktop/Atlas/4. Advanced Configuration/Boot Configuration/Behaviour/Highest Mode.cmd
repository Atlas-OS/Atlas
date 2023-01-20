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

:: https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings/

echo Enables boot applications to use the highest graphical mode exposed by the firmware.
echo Makes safe mode and booting use the highest resolution.
echo]
echo What would you like to do?
echo [1] Enable
echo [2] Disable (default)
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %errorlevel%==1 (
	goto enable
) else (
	goto disable
)

:enable
echo]
bcdedit /set highestmode true > nul
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

:disable
echo]
bcdedit /deletevalue highestmode > nul
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