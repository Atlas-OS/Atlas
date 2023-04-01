@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if !errorlevel! == 1 (
    echo The NVIDIA Display Container LS service does not exist, thus you cannot continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)
reg query "HKCR\DesktopBackground\shell\NVIDIAContainer" > nul 2>&1
if !errorlevel! == 1 (
    echo The context menu does not exist, thus you cannot continue.
    pause
    exit /b 1
)

echo Explorer will be restarted to ensure that the context menu is removed.
pause

reg delete "HKCR\DesktopBackground\Shell\NVIDIAContainer" /f > nul 2>&1

:: delete icon exe
taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe

echo Finished, changes have been applied.
pause
exit /b