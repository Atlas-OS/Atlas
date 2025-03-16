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

:: https://winaero.com/how-to-disable-automatic-repair-at-windows-10-boot

echo Automatic repair mostly does not do anything to help, and could cause issues.
echo]
echo What would you like to do?
echo [1] Disable automatic repair
echo [2] Enable automatic repair (default)
echo]
choice /c 12 /n /m "Type 1 or 2: "
if %ERRORLEVEL% == 1 (
	goto disable
) else (
	goto enable
)

:disable
bcdedit /set {current} bootstatuspolicy IgnoreAllFailures > nul
goto finish

:enable
bcdedit /set {current} bootstatuspolicy DisplayAllFailures > nul
goto finish

:finish
echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b
