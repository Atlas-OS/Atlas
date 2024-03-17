@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

call setSvc.cmd WSearch 4
sc stop WSearch > nul 2>&1
call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /hide cortana-windowssearch

echo Finished.
pause
exit /b