@echo off
::setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

set "taskName=TaskName:      "

net stop CSC > nul 2>&1
net stop CscService > nul 2>&1
call setSvc.cmd CSC 4
call setSvc.cmd CscService 4

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" /v "Enabled" /t REG_DWORD /d "0" /f > nul

set "root=\Microsoft\Windows\Offline Files"
schtasks /change /tn "%root%\Background Synchronization" /disable > nul 2>&1
schtasks /change /tn "%root%\Logon Synchronization" /disable > nul 2>&1

:: restart Explorer
taskkill /f /im sihost.exe > nul 2>&1

echo Completed.
pause
exit /b