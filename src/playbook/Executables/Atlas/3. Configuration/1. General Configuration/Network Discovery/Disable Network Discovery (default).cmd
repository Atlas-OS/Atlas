@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

call setSvc.cmd fdPHost 4
call setSvc.cmd FDResPub 4
call setSvc.cmd lmhosts 4
call setSvc.cmd netman 3
call setSvc.cmd NlaSvc 2
call setSvc.cmd SSDPSRV 4

echo Finished, please reboot your device for changes to apply.
pause
exit /b