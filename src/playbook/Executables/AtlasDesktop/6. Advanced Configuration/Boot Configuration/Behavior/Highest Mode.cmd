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

echo Enables boot applications to use the highest graphical mode exposed by the firmware.
echo Makes safe mode and booting use the highest resolution.
echo]
echo What would you like to do?
echo [1] Disable (default)
echo [2] Enable
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %ERRORLEVEL% == 1 (
	goto disable
) else (
	goto enable
)

:disable
bcdedit /deletevalue {globalsettings} highestmode > nul 2>&1
goto finish

:enable
bcdedit /set {globalsettings} highestmode true > nul
goto finish

:finish
echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b
