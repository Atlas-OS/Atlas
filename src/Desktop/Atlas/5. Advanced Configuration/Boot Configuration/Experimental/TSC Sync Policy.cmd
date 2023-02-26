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

echo Controls the times stamp counter synchronization policy.
echo Little information exists about this option.
echo]
echo What would you like to do?
echo [1] Set to 'Default' (default)
echo [2] Set to 'Legacy'
echo [3] Set to 'Enhanced'
echo]
choice /c 123 /n /m "Type 1 or 2 or 3: "
if %errorlevel%==1 (goto default)
if %errorlevel%==2 (goto legacy)
if %errorlevel%==3 (goto enhanced)

:default
echo]
bcdedit /set tscsyncpolicy default
if not %errorlevel%==0 (goto fail) else (goto success)

:legacy
echo]
bcdedit /set tscsyncpolicy legacy
if not %errorlevel%==0 (goto fail) else (goto success)

:enhanced
echo]
bcdedit /set tscsyncpolicy enhanced
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