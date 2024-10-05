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

:: Unpin 'Network' from Explorer sidebar
reg import "%windir%\AtlasDesktop\3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).reg" > nul

call setSvc.cmd fdPHost 4
call setSvc.cmd FDResPub 4
call setSvc.cmd lmhosts 4
call setSvc.cmd SSDPSRV 4

echo Finished, please reboot your device for changes to apply.
pause
exit /b