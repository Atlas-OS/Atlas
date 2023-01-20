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

echo Disable some of the kernel memory mitigations. 
echo Causes boot crash/loops if Intel SGX is enforced and not set to "Application Controlled" or "Off" in your firmware. 
echo Gamers do not use SGX under any possible circumstance.
echo]
echo NOTE: I could not find any documentation on this, except from Melody's website.
echo]
echo What would you like to do?
echo [1] Disable mitigations
echo [2] Delete values (default)
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %errorlevel%==1 (
	goto disable
) else (
	goto delete
)

:disable
echo]
bcdedit /set allowedinmemorysettings 0x0 > nul
if not %errorlevel%==0 (goto fail)
bcdedit /set isolatedcontext No > nul
if not %errorlevel%==0 (goto fail) else (goto success)

:delete
echo]
bcdedit /deletevalue allowedinmemorysettings > nul
if not %errorlevel%==0 (echo Something went wrong deleting the value 'allowedinmemorysettings', maybe it never existed.)
bcdedit /deletevalue isolatedcontext > nul
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