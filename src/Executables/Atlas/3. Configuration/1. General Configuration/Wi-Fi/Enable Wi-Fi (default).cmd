@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

!setSvcScript! netprofm 3
!setSvcScript! NlaSvc 2
!setSvcScript! WlanSvc 2
!setSvcScript! vwififlt 1
!setSvcScript! eventlog 2

echo Finished, please reboot your device for changes to apply.
pause
exit /b