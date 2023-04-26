@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: check if the service exists
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if !errorlevel! == 1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)

echo Disabling the 'NVIDIA Display Container LS' service will stop the NVIDIA Control Panel from working.
echo It will most likely break other NVIDIA driver features as well.
echo These scripts are aimed at users that have a stripped driver, and people that barely touch the NVIDIA Control Panel.
echo]
echo You can enable the NVIDIA Control Panel and the service again by running the enable script.
echo Additionally, you can add a context menu to the desktop with another script in the Atlas folder.
echo]
echo Read README.txt for more info.
pause

call setSvc.cmd NVDisplay.ContainerLocalSystem 4
sc stop NVDisplay.ContainerLocalSystem > nul 2>&1

cls & echo Finished, changes have been applied.
pause
exit /b