@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

powercfg /hibernate off
powercfg /setactive scheme_current

echo Finished, changes have been applied.
pause
exit /b