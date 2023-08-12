@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

taskkill /f /im SetTimerResolution.exe > nul 2>&1
schtasks /delete /tn "Force Timer Resolution" /f > nul

echo Finished, changes have been applied.
pause
exit /b