@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:: https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings

echo What would you like to do?
echo [1] Disable the boot logo
echo [2] Enable the boot logo (default)
echo]
choice /c 12 /n /m "Type 1 or 2: "
if !errorlevel! == 1 (
	goto disable
) else (
	goto enable
)

:disable
echo]
bcdedit /set {globalsettings} custom:16000067 true > nul
goto finish

:enable
echo]
bcdedit /deletevalue {globalsettings} custom:16000067 > nul 2>&1
goto finish

:finish
echo Finished, please reboot your device for changes to apply.
pause
exit /b