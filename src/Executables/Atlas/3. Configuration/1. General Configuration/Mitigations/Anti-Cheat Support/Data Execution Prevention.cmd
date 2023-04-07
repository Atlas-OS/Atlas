@echo off
setlocal ENABLEEXTENSIONS
setlocal DISABLEDELAYEDEXPANSION

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set

echo Data Execution Prevention (DEP). It is a set of hardware and software technologies designed to
echo prevent harmful code from running in protected memory locations.
echo]
echo What would you like to do?
echo [1] OptIn - Anti-cheat compatibility, protects OS components only (default)
echo [2] OptOut - Disable DEP everywhere, but it can be enabled per process
echo [3] AlwaysOn - Enables DEP everywhere, no matter what, anti-cheat compatibility
echo [4] AlwaysOff - Disables DEP everywhere, no matter what
echo]
choice /c 1234 /n /m "Type 1 or 2 or 3 or 4: "
if %errorlevel%==1 (goto optin)
if %errorlevel%==2 (goto optout)
if %errorlevel%==3 (goto alwayson)
if %errorlevel%==4 (goto alwaysoff)

:optin
echo]
bcdedit /set nx OptIn > nul
if %errorlevel%==0 (goto success) else (goto fail)

:optout
echo]
bcdedit /set nx OptOut > nul
if %errorlevel%==0 (goto success) else (goto fail)

:alwayson
echo]
bcdedit /set nx AlwaysOn > nul
PowerShell -NoP -C "Set-ProcessMitigation -System -Enable DEP, EmulateAtlThunks" > nul
if %errorlevel%==0 (goto success) else (goto fail)

:alwaysoff
echo]
bcdedit /set nx AlwaysOff > nul
if %errorlevel%==0 (goto success) else (goto fail)

:success
echo Finished, please restart to see the changes.
pause
exit /b

:fail
echo Something went wrong doing the BCDEDIT command!
echo Look at the error above, if there is one.
pause
exit /b 1