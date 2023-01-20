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

echo Avoid the use of uncontiguous portions of low-memory from the OS. 
echo Boosts memory performance and improves microstuttering at least 80% of the cases. 
echo Also fixes the command buffer stutter after disabling 5-level paging on 10th gen Intel.
echo Causes system freeze on unstable memory sticks.
echo]
echo NOTE: I could only find any info on this from Melody's website.
echo]
echo What would you like to do?
echo [1] Enable
echo [2] Delete values (default)
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %errorlevel%==1 (
	goto enable
) else (
	goto delete
)

:enable
echo]
:: Not documented
bcdedit /set firstmegabytepolicy UseAll > nul
if not %errorlevel%==0 (echo Setting value 'firstmegabytepolicy' failed!)
:: Not documented
bcdedit /set avoidlowmemory 0x8000000 > nul
if not %errorlevel%==0 (echo Setting value 'avoidlowmemory' failed!)
:: Does nothing on Windows 8 and over?
:: https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set
bcdedit /set nolowmem Yes > nul
if not %errorlevel%==0 (echo Setting value 'nolowmem' failed!)
goto success

:delete
echo]
bcdedit /deletevalue firstmegabytepolicy > nul
if not %errorlevel%==0 (echo Deleting value 'firstmegabytepolicy' failed!)
bcdedit /deletevalue avoidlowmemory > nul
if not %errorlevel%==0 (echo Deleting value 'avoidlowmemory' failed!)
bcdedit /deletevalue nolowmem > nul
if not %errorlevel%==0 (echo Deleting value 'nolowmem' failed!)
goto success

:success
echo]
echo Finished, please restart to see the changes.
pause
exit /b 0