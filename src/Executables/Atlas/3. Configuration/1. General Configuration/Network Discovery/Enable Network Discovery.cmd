@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

call setSvc,cmd eventlog 2
call setSvc,cmd NlaSvc 2
call setSvc,cmd lmhosts 3
call setSvc,cmd netman 3

echo Finished, please reboot your device for changes to apply.
pause
exit /b