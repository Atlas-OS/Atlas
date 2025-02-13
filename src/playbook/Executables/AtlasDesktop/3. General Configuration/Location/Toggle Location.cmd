@echo off
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

reg query "HKLM\SOFTWARE\AtlasOS\Location" /v state > nul 2>&1
if %errorlevel% neq 0 (
    echo Location state registry key not found. Creating it...
    reg add "HKLM\SOFTWARE\AtlasOS\Location" /v state /t REG_DWORD /d 0 /f > nul
)

:menu
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\AtlasOS\Location" /v state 2^>nul ^| findstr REG_DWORD') do set "current_state=%%A"
set /a current_state=%current_state%

if %current_state%==1 (
    set "option1=Disable"
    set "option2=Enable (Current)"
) else (
    set "option1=Disable (Current)"
    set "option2=Enable"
)

cls
echo Toggle Find My Device and Location Services
echo.
echo 1) %option1%
echo 2) %option2%
echo.
set /p "choice=Select an option (1-2): "

if "%choice%"=="1" (
    if %current_state%==0 (
        echo Find My Device and Location services are already disabled.
        pause > nul
    ) else (
        echo Disabling Find My Device and Location services...
        reg add "HKLM\SOFTWARE\AtlasOS\Location" /v state /t REG_DWORD /d 0 /f > nul

        reg add "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /v AllowFindMyDevice /t REG_DWORD /d 0 /f > nul
        reg add "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /v LocationSyncEnabled /t REG_DWORD /d 0 /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f > nul

        sc config lfsvc start=disabled > nul 2>&1
        sc config MapsBroker start=disabled > nul 2>&1
        sc stop lfsvc > nul 2>&1
        sc stop MapsBroker > nul 2>&1

        for %%a in (
            "privacy-location"
            "findmydevice"
        ) do (
            call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /hide %%~a /silent
        )
        goto finish
    )
)

if "%choice%"=="2" (
    if %current_state%==1 (
        echo Find My Device and Location services are already enabled.
        pause > nul
    ) else (
        echo Enabling Find My Device and Location services...
        reg add "HKLM\SOFTWARE\AtlasOS\Location" /v state /t REG_DWORD /d 1 /f > nul

        reg delete "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /f > nul 2>&1
        reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /f > nul 2>&1

        sc config lfsvc start=demand > nul 2>&1
        sc config MapsBroker start=auto > nul 2>&1
        sc start lfsvc > nul 2>&1
        sc start MapsBroker > nul 2>&1

        call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide privacy-location
        call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide findmydevice /silent

        start ms-settings:privacy-location
        goto finish
    )
)

echo Invalid selection. Exiting...
exit /b

:finish
echo.
echo Changes applied successfully.
echo Press any key to exit...
pause > nul
exit /b