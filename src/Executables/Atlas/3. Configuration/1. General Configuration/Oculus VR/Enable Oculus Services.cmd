@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

:: Enable workstation and hidden dependencies
!setSvcScript! KSecPkg 0
!setSvcScript! LanmanWorkstation 2
!setSvcScript! mrxsmb 3
!setSvcScript! mrxsmb20 3
!setSvcScript! rdbss 1
!setSvcScript! srv2 3

:: QWAVE
!setSvcScript! QwaveDrv 3
!setSvcScript! Qwave 3
!setSvcScript! FontCache 2

echo Finished, please reboot your device for changes to apply.
pause
exit /b