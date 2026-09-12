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

reg delete "HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle" /f

:: Breaks 'Receive updates for other Microsoft products'
:: reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f > nul 2>&1
if "%~1"=="/silent" exit /b

echo.
echo Automatic Updates have been enabled.
echo Press any key to exit...
pause > nul
exit /b
