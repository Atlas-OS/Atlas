@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

net stop CSC > nul 2>&1
net stop CscService > nul 2>&1
call setSvc.cmd CSC 4
call setSvc.cmd CscService 4
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" /v "Enabled" /t REG_DWORD /d "0" /f > nul
taskkill /f /im sihost.exe

echo Completed.
pause
exit /b