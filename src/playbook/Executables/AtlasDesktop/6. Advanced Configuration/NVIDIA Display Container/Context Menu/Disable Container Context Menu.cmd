@echo off

fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	set "___args="%~f0" %*"
	powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
		echo You must run this script as admin.
		exit /b 1
	)
	exit /b
)

:: check if the service exists
reg query "HKCR\DesktopBackground\shell\NVIDIAContainer" > nul 2>&1 || (
    echo The context menu does not exist, thus you cannot continue.
    echo]
    pause
    exit /b 1
)

echo Explorer will be restarted to ensure that the context menu is removed.
pause

reg delete "HKCR\DesktopBackground\Shell\NVIDIAContainer" /f > nul 2>&1

:: delete icon exe
taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe

echo Finished, changes have been applied.
pause
exit /b