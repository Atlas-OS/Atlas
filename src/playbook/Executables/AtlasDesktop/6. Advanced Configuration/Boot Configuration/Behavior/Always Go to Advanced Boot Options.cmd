@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:: https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings

echo This tweak enables the advanced boot options to be shown on each boot.
echo]
echo What would you like to do?
echo [1] Disable always going to the advanced boot options (default)
echo [2] Enable always going to the advanced boot options
echo]
choice /c 12 /n /m "Type 1 or 2: "
if !errorlevel! == 1 (
	goto disable
) else (
	goto enable
)

:disable
echo]
bcdedit /deletevalue advancedoptions > nul 2>&1
goto finish

:enable
echo]
bcdedit /set {globalsettings} advancedoptions true > nul
goto finish

:finish
echo Finished, please reboot your device for changes to apply.
pause
exit /b