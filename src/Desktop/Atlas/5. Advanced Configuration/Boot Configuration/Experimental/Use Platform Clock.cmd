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

echo Forces the use of the platform clock as the system's performance counter.
echo]
echo WARNING: This almost always gives negative results, I would NOT recommend setting this to 'yes'.
echo          Please just use the defaults. If you are going to use this anyways, please use TimerBench to test it.
echo]
echo What would you like to do?
echo [1] Set to 'yes'
echo [2] Set to 'no'
echo [3] Delete the value (default)
echo]
choice /c 123 /n /m "Type 1 or 2 or 3: "
if %errorlevel%==1 (goto yes)
if %errorlevel%==2 (goto no)
if %errorlevel%==3 (goto deletevalue)

:yes
echo]
bcdedit /set useplatformclock yes
if not %errorlevel%==0 (goto fail) else (goto success)

:no
echo]
bcdedit /set useplatformclock no
if not %errorlevel%==0 (goto fail) else (goto success)

:deletevalue
echo]
bcdedit /deletevalue useplatformclock
if not %errorlevel%==0 (goto fail) else (goto success)

:fail
echo]
echo Something went wrong doing the BCDEDIT command!
echo Look at the error above, if there is one.
echo Potentially the value is already deleted?
pause
exit /b 1

:success
echo]
echo Finished, please restart to see the changes.
pause
exit /b 0