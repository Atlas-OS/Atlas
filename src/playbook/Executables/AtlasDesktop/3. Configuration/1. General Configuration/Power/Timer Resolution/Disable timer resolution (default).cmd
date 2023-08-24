@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /f > nul
taskkill /f /im SetTimerResolution.exe > nul 2>&1
schtasks /delete /tn "Force Timer Resolution" /f > nul 2>&1

echo Finished, changes have been applied.
pause
exit /b