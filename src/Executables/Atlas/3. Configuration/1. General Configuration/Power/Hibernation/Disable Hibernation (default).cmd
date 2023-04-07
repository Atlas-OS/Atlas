@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

powercfg /h off > nul
powercfg -setactive scheme_current > nul

echo Finished, changes have been applied.
pause
exit /b