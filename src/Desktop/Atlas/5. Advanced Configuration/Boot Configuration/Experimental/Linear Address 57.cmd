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

:: https://sites.google.com/view/melodystweaks/basictweaks

echo Disable 57-bits 5-level paging, also known as "Linear Address 57". Only 100% effective on 10th gen Intel. 
echo 256 TB of virtual memory per-disk is way much more than enough anyway.
echo]
echo NOTE: Melody recommends to also use the 'Avoid low memory' batch file to avoid command buffer stutter.
echo]
echo What would you like to do?
echo [1] Enable Linear Address 57 (default)
echo [2] Disable Linear Address 57
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %errorlevel%==1 (
	goto enable
) else (
	goto disable
)

:enable
echo]
bcdedit /deletevalue linearaddress57 > nul
if not %errorlevel%==0 (goto fail) else (goto success)

:disable
echo]
bcdedit /set linearaddress57 OptOut > nul
if not %errorlevel%==0 (goto fail) else (goto success)

:fail
echo]
echo Something went wrong doing the BCDEDIT command!
echo Look at the error above, if there is one.
pause
exit /b 1

:success
echo]
echo Finished, please restart to see the changes.
pause
exit /b 0