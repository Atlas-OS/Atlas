@echo off
set "settingName=AutomaticUpdates"
set "stateValue=1"
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

reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul


reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle" /v "Icon" /d "powercpl.dll" /f
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle" /v "SubCommands" /d "" /f
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle" /v "Position" /d "Bottom" /f
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle" /v "MUIVerb" /d "CPU Idle" /f

reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle\Shell\Disable Idle" /v "MUIVerb" /d "Disable Idle" /f
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle\Shell\Disable Idle" /v "Icon" /d "powercpl.dll" /f
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle\Shell\Disable Idle\Command" /d "cmd /c \"\"%%windir%%\\AtlasDesktop\\3. General Configuration\\CPU Idle\\Disable Idle.cmd\"\" /silent" /f

reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle\Shell\Disable Idle\Command" /v "Icon" /d "powercpl.dll" /f
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle\Shell\Enable Idle" /v "MUIVerb" /d "Enable Idle" /f
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle\Shell\Enable Idle\Command" /d "cmd /c \"\"%%windir%%\\AtlasDesktop\\3. General Configuration\\CPU Idle\\Enable Idle (default).cmd\"\" /silent" /f


:: Breaks 'Receive updates for other Microsoft products'
:: reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f > nul 2>&1
if "%~1"=="/silent" exit /b

echo.
echo Automatic Updates have been enabled.
echo Press any key to exit...
pause > nul
exit /b
