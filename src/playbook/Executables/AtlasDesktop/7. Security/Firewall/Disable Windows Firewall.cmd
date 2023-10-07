@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

echo This WILL break Microsoft Store and AppX deployment, and isn't recommended.
timeout /t 2 /nobreak > nul
pause & cls

call setSvc.cmd BFE 4
call setSvc.cmd mpssvc 4

echo Finished, please reboot your device for changes to apply.
pause
exit /b