@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

call setSvc.cmd CSC 1
call setSvc.cmd CscService 2
net start CSC > nul 2>&1
net start CscService > nul 2>&1

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" /v "Enabled" /t REG_DWORD /d "1" /f > nul

set "root=\Microsoft\Windows\Offline Files"
schtasks /change /tn "%root%\Background Synchronization" /disable > nul 2>&1
schtasks /change /tn "%root%\Logon Synchronization" /disable > nul 2>&1

:: restart explorer
taskkill /f /im sihost.exe

echo Completed.
pause
exit /b