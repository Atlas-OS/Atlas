@echo off
set "___args="%~f0" %*"

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
    echo Running as Trusted Installer...
    call RunAsTI.cmd "%~f0" %*
    exit /b
)

fltmc > nul 2>&1 || (
    echo Administrator privileges are required.
    powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
        echo You must run this script as admin.
        if "%*"=="" pause
        exit /b 1
    )
    exit /b
)

reg query "HKLM\SOFTWARE\AtlasOS\FSOGameBar" /v state > nul 2>&1
if %errorlevel% neq 0 (
    echo FSOGameBar state registry key not found. Creating it...
    reg add "HKLM\SOFTWARE\AtlasOS\FSOGameBar" /v state /t REG_DWORD /d 1 /f > nul
)

:menu
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\AtlasOS\FSOGameBar" /v state 2^>nul ^| findstr REG_DWORD') do set "current_state=%%A"
set /a current_state=%current_state%

if %current_state%==1 (
    set "option1=Disable"
    set "option2=Enable (Current)"
) else (
    set "option1=Disable (Current)"
    set "option2=Enable"
)

cls
echo Toggle FSO and Game Bar
echo.
echo 1) %option1%
echo 2) %option2%
echo.
set /p "choice=Select an option (1-2): "

if "%choice%"=="1" (
    if %current_state%==0 (
        echo FSO and Game Bar are already disabled.
        pause > nul
    ) else (
        echo Disabling FSO and Game Bar...
        reg add "HKLM\SOFTWARE\AtlasOS\FSOGameBar" /v state /t REG_DWORD /d 0 /f > nul

        (
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_DSEBehavior" /t REG_DWORD /d "2" /f
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "1" /f
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d "2" /f
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "1" /f

            reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "__COMPAT_LAYER" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f

            reg add "HKCU\System\GameBar" /v "GamePanelStartupTipIndex" /t REG_DWORD /d "3" /f
            reg add "HKCU\System\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d "0" /f
            reg add "HKCU\System\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d "0" /f

            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d "0" /f

            reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_DWORD /d "0" /f

            reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f

            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f
        ) > nul 2>&1

        goto finish
    )
)

if "%choice%"=="2" (
    if %current_state%==1 (
        echo FSO and Game Bar are already enabled.
        pause > nul
    ) else (
        echo Enabling FSO and Game Bar...
        reg add "HKLM\SOFTWARE\AtlasOS\FSOGameBar" /v state /t REG_DWORD /d 1 /f > nul

        (
            reg delete "HKCU\System\GameConfigStore" /v "GameDVR_DSEBehavior" /f
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "0" /f
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f
            reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /f
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "0" /f

            reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "__COMPAT_LAYER" /f

            reg delete "HKCU\System\GameBar" /v "GamePanelStartupTipIndex" /f
            reg delete "HKCU\System\GameBar" /v "ShowStartupPanel" /f
            reg delete "HKCU\System\GameBar" /v "UseNexusForGameBarEnabled" /f

            reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /f

            reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_DWORD /d "1" /f

            reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "1" /f

            reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /f
        ) > nul 2>&1
        
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