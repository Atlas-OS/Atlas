@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Enable Lanman Workstation (SMB) as a dependency
call setSvc.cmd KSecPkg 0
call setSvc.cmd LanmanWorkstation 2
call setSvc.cmd mrxsmb 3
call setSvc.cmd mrxsmb20 3
call setSvc.cmd rdbss 1
call setSvc.cmd srv2 3

DISM /Online /Enable-Feature /FeatureName:"SmbDirect" /NoRestart

:: Enable EventLog as a dependency
call setSvc.cmd eventlog 2

call setSvc.cmd fdPHost 3
call setSvc.cmd FDResPub 3
call setSvc.cmd lmhosts 3
call setSvc.cmd netman 3
call setSvc.cmd NlaSvc 2
call setSvc.cmd SSDPSRV 3

echo Finished, please reboot your device for changes to apply.
pause
exit /b