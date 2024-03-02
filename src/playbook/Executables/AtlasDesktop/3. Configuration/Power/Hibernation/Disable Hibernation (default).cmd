@echo off

if "%~1" == "/silent" goto main

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:main
powercfg /hibernate off

if "%~1" == "/silent" exit

echo Finished, changes have been applied.
pause
exit /b