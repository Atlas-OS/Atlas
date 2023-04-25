@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings/

echo This tweak allows you to disable/enable the new boot menu.
echo However, it is slower and more annoying than the legacy Windows 7 boot menu.
echo]
echo What would you like to do?
echo [1] Disable the new boot menu (default)
echo [2] Enable the new boot menu
echo]
choice /c 12 /n /m "Type 1 or 2: "
if !errorlevel! == 1 (
	goto disable
) else (
	goto enable
)

:disable
echo]
bcdedit /set {default} bootmenupolicy legacy > nul 2>&1
goto finish

:enable
echo]
bcdedit /set {default} bootmenupolicy standard > nul 2>&1
goto finish

:finish
echo Finished, please reboot your device for changes to apply.
pause
exit /b
