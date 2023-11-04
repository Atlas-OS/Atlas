@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

powercfg /hibernate on
powercfg /hibernate /type full
powercfg /setactive scheme_current

if "%~1" == "/silent" exit /b

echo Finished, changes have been applied.
pause
exit /b
