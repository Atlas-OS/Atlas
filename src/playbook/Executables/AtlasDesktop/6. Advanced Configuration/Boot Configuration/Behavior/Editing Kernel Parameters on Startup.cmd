@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:: https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings

echo You can specify additional boot options for the Windows kernel at boot time.
echo]
echo What would you like to do?
echo [1] Disable editing of kernel parameters on startup (default)
echo [2] Enable editing of kernel parameters on startup
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %errorlevel% == 1 (
	goto disable
) else (
	goto enable
)

:disable
echo]
bcdedit /deletevalue {globalsettings} optionsedit > nul 2>&1
goto finish

:enable
echo]
bcdedit /set {globalsettings} optionsedit true > nul
goto finish

:finish
echo Finished, please reboot your device for changes to apply.
pause
exit /b