@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Enable workstation and hidden dependencies
call setSvc.cmd KSecPkg 0
call setSvc.cmd LanmanWorkstation 2
call setSvc.cmd mrxsmb 3
call setSvc.cmd mrxsmb20 3
call setSvc.cmd rdbss 1
call setSvc.cmd srv2 3

:: QWAVE
call setSvc.cmd QwaveDrv 3
call setSvc.cmd Qwave 3
call setSvc.cmd FontCache 2

cls & echo Finished, please reboot your device for changes to apply.
pause
exit /b