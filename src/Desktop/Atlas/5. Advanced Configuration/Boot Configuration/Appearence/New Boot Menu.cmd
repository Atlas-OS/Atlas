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

echo This tweak allows you to disable/enable the new boot menu.
echo However, it is slower and annoying than the legacy Windows 7 boot menu.
echo]
echo What would you like to do?
echo [1] Disable the new boot menu (default)
echo [2] Enable the boot logo
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %errorlevel%==1 (
	goto disable
) else (
	goto enable
)

:disable
echo]
bcdedit /set {default} bootmenupolicy legacy > nul
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

:enable
echo]
bcdedit /set {default} bootmenupolicy standard > nul
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