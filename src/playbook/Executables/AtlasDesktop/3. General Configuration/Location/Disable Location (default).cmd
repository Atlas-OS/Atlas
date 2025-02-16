@echo off
set "settingName=Location"
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

reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

(
    sc config lfsvc start=disabled
    sc config MapsBroker start=disabled
    reg add "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /v AllowFindMyDevice /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /v LocationSyncEnabled /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "ShowGlobalPrompts" /t REG_DWORD /d 0 /f
) > nul

(
    sc stop lfsvc
    sc stop MapsBroker
) > nul 2>&1

for %%a in (
    "privacy-location"
    "findmydevice"
) do (
    call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /hide %%~a /silent
)

if "%~1"=="/silent" exit /b

echo.
echo Location services have been disabled.
echo Press any key to exit...
pause
exit /b