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

:: https://learn.microsoft.com/en-us/windows/security/identity-protection/credential-guard/credential-guard-manage

echo Data Execution Prevention (DEP). It is a set of hardware and software technologies designed to 
echo prevent harmful code from running in protected memory locations.
echo]
echo What would you like to do?
echo [1] OptIn - anti-cheat compatibility, protects OS components only (default)
echo [2] OptOut - disable DEP everywhere, but it can be enabled per process
echo [3] AlwaysOn - Enables DEP everywhere, no matter what
echo [4] AlwaysOff - Disables DEP everywhere, no matter what
echo]
choice /c 1234 /n /m "Type 1 or 2 or 3 or 4: "
if %errorlevel%==1 (goto optin)
if %errorlevel%==2 (goto optout)
if %errorlevel%==3 (goto alwayson)
if %errorlevel%==4 (goto alwaysoff)

:optin
echo]
bcdedit /set nx optin > nul
if %errorlevel%==0 (goto success) else (goto fail)

:optout
echo]
bcdedit /set nx optout > nul
if %errorlevel%==0 (goto success) else (goto fail)

:alwayson
echo]
bcdedit /set nx alwayson > nul
if %errorlevel%==0 (goto success) else (goto fail)

:alwaysoff
echo]
bcdedit /set nx alwaysoff > nul
if %errorlevel%==0 (goto success) else (goto fail)

:success
echo Finished, please restart to see the changes.
pause
exit /b 0

:fail
echo Something went wrong doing the BCDEDIT command!
echo Look at the error above, if there is one.
pause
exit /b 1