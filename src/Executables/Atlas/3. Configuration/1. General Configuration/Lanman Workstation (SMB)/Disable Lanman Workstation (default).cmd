@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

!setSvcScript! KSecPkg 4
!setSvcScript! LanmanWorkstation 4
!setSvcScript! mrxsmb 4
!setSvcScript! mrxsmb20 4
!setSvcScript! rdbss 3
!setSvcScript! srv2 4

DISM /Online /Disable-Feature /FeatureName:SmbDirect /NoRestart

echo Finished, please reboot your device for changes to apply.
pause
exit /b