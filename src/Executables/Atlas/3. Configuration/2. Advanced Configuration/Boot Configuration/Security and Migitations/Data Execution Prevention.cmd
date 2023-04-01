@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
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
if !errorlevel! == 1 (goto optin)
if !errorlevel! == 2 (goto optout)
if !errorlevel! == 3 (goto alwayson)
if !errorlevel! == 4 (goto alwaysoff)

:optin
echo]
bcdedit /set nx OptIn > nul 2>&1
goto finish

:optout
echo]
bcdedit /set nx OptOut > nul 2>&1
goto finish

:alwayson
echo]
bcdedit /set nx AlwaysOn > nul 2>&1
goto finish

:alwaysoff
echo]
bcdedit /set nx AlwaysOff > nul 2>&1
goto finish

:finish
echo Finished, please reboot your device for changes to apply.
pause
exit /b