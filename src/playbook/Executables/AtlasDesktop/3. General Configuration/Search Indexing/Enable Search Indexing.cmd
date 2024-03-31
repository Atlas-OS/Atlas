@echo off
setlocal EnableDelayedExpansion
if "%~1"=="/silent" goto main

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:main
(
	sc config WSearch start=auto
	sc start WSearch
) > nul
call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide cortana-windowssearch

if "%~1"=="/silent" exit /b
echo Finished, please reboot your device for changes to apply.
pause
exit /b