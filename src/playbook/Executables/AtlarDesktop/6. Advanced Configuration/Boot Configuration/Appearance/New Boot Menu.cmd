@echo off

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
		echo You must run this script as admin.
		if "%*"=="" pause
		exit /b 1
	)
	exit /b
)

:: https://winaero.com/how-to-disable-windows-8-boot-logo-spining-icon-and-some-other-hidden-settings

echo This tweak allows you to disable/enable the new boot menu.
echo However, it is slower and more annoying than the legacy Windows 7 boot menu.
echo]
echo What would you like to do?
echo [1] Disable the new boot menu (default)
echo [2] Enable the new boot menu
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %ERRORLEVEL% == 1 (
	goto disable
) else (
	goto enable
)

:disable
bcdedit /set {default} bootmenupolicy legacy > nul
goto finish

:enable
bcdedit /set {default} bootmenupolicy standard > nul 2>&1
goto finish

:finish
echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b
