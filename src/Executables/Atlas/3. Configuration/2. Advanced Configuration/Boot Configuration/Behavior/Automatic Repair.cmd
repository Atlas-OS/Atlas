@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: https://winaero.com/how-to-disable-automatic-repair-at-windows-10-boot/

echo Automatic repair mostly does not do anything to help, and could cause issues.
echo]
echo What would you like to do?
echo [1] Disable automatic repair
echo [2] Enable automatic repair (default)
echo]
choice /c 12 /n /m "Type 1 or 2: "
if !errorlevel! == 1 (
	goto disable
) else (
	goto enable
)

:disable
echo]
bcdedit /set {current} bootstatuspolicy IgnoreAllFailures > nul 2>&1
goto finish

:enable
echo]
bcdedit /set {current} bootstatuspolicy DisplayAllFailures > nul 2>&1
goto finish

:finish
echo Finished, please reboot your device for changes to apply.
pause
exit /b
