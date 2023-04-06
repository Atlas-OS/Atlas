@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

:: check if the service exists
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if !errorlevel! == 1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)

call setSvc,cmd NVDisplay.ContainerLocalSystem 2
sc start NVDisplay.ContainerLocalSystem > nul 2>&1

echo Finished, changes have been applied.
pause
exit /b