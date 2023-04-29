@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings/

echo Enables boot applications to use the highest graphical mode exposed by the firmware.
echo Makes safe mode and booting use the highest resolution.
echo]
echo What would you like to do?
echo [1] Disable (default)
echo [2] Enable
echo]
choice /c 12 /n /m "Type 1 or 2: "
if !errorlevel! == 1 (
	goto disable
) else (
	goto enable
)

:disable
echo]
bcdedit /deletevalue {globalsettings} highestmode > nul 2>&1
goto finish

:enable
echo]
bcdedit /set {globalsettings} highestmode true > nul 2>&1
goto finish

:finish
echo Finished, please reboot your device for changes to apply.
pause
exit /b
