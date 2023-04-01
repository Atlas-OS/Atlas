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
echo Explorer will be restarted to ensure that the context menu works.
pause

reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "Icon" /t REG_SZ /d "NVIDIA.ico,0" /f > nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "MUIVerb" /t REG_SZ /d "NVIDIA Container" /f > nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "Position" /t REG_SZ /d "Bottom" /f > nul 2>&1
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "SubCommands" /t REG_SZ /d "" /f > nul 2>&1
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001" /v "HasLUAShield" /t REG_SZ /d "" /f > nul 2>&1
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001" /v "MUIVerb" /t REG_SZ /d "Enable NVIDIA Display Container LS" /f > nul 2>&1
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002\command" /ve /t REG_SZ /d "\"C:\Users\%username%\Desktop\Atlas\3. Configuration\2. Advanced Configuration\NVIDIA Display Container\Enable NVIDIA Display Container LS.cmd"" /f > nul 2>&1
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002" /v "HasLUAShield" /t REG_SZ /d "" /f > nul 2>&1
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002" /v "MUIVerb" /t REG_SZ /d "Disable NVIDIA Display Container LS" /f > nul 2>&1
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002\command" /ve /t REG_SZ /d "\"C:\Users\%username%\Desktop\Atlas\3. Configuration\2. Advanced Configuration\NVIDIA Display Container\Disable NVIDIA Display Container LS.cmd"" /f > nul 2>&1

taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe

echo Finished, changes have been applied.
pause
exit /b