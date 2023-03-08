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
:: https://en.wikipedia.org/wiki/Tickless_kernel

echo Enables and disables dynamic timer tick feature.
echo Search 'Tickless Kernel' on Wikipedia for more info.
echo]
echo What would you like to do?
echo [1] Set to yes (default)
echo [2] Delete value
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %errorlevel%==1 (
	goto yes
) else (
	goto delete
)

:yes
echo]
bcdedit /set disabledynamictick yes > nul
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
bcdedit /deletevalue disabledynamictick > nul
if not %errorlevel%==0 (
	echo Something went wrong doing the BCDEDIT command!
	echo Look at the error above, if there is one.
	echo]
	echo However, the value most likely just does not exist, if there is no output.
	pause
	exit /b 1
) else (
	echo Finished, please restart to see the changes.
	pause
	exit /b 0
)