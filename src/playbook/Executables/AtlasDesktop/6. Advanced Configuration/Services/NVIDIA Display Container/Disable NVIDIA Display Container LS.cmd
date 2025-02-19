@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=NVidiaDisplayContainer"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=0"
set "scriptPath=%~f0"

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
    echo Administrator privileges are required.
    powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
        echo You must run this script as admin.
        if "%*"=="" pause
        exit /b 1
    )
    exit /b
)

:: Update Registry (State and Path)
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

if not "%~1"=="/silent" call "%windir%\AtlasModules\Scripts\serviceWarning.cmd" %*

:: check if the service exists
reg query "HKLM\SYSTEM\CurrentControlSet\Services\NVDisplay.ContainerLocalSystem" > nul 2>&1 || (
    echo The NVIDIA Display Container LS service does not exist, you cannot continue.
	echo You may not have NVIDIA drivers installed.
    echo]
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
echo See 'Must Read First' for more info.
echo]
pause

call setSvc.cmd NVDisplay.ContainerLocalSystem 4
sc stop NVDisplay.ContainerLocalSystem > nul 2>&1
if "%~1"=="/silent" exit /b

echo Finished, changes have been applied.
pause
exit /b