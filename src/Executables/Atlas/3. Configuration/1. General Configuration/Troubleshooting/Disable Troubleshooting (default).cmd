@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog" /v "Start" /t REG_DWORD /d "0" /f > nul 2>&1
!setSvcScript! DPS 4
!setSvcScript! WdiServiceHost 4
!setSvcScript! WdiSystemHost 4

echo Finished, please reboot your device for changes to apply.
pause
exit /b