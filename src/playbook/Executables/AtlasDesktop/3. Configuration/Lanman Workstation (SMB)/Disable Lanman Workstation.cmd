@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

call setSvc.cmd KSecPkg 4
call setSvc.cmd LanmanServer 4
call setSvc.cmd LanmanWorkstation 4
call setSvc.cmd mrxsmb 4
call setSvc.cmd mrxsmb20 4
call setSvc.cmd rdbss 3
call setSvc.cmd srv2 4

DISM /Online /Disable-Feature /FeatureName:"SmbDirect" /NoRestart

echo Finished, please reboot your device for changes to apply.
pause
exit /b