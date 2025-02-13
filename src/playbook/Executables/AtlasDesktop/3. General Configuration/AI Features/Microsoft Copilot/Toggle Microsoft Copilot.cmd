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

reg query "HKLM\SOFTWARE\AtlasOS\Copilot" /v state > nul 2>&1
if %errorlevel% neq 0 (
    echo Copilot state registry key not found. Creating it...
    reg add "HKLM\SOFTWARE\AtlasOS\Copilot" /v state /t REG_DWORD /d 0 /f > nul
)

for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\AtlasOS\Copilot" /v state 2^>nul ^| findstr REG_DWORD') do set "current_state=%%A"

set /a current_state=%current_state%

if %current_state%==1 (
    set "option1=Disable"
    set "option2=Enable (Current)"
) else (
    set "option1=Disable (Current)"
    set "option2=Enable"
)

cls
echo Toggle Microsoft Copilot   
echo.
echo 1) %option1%
echo 2) %option2%
echo.
set /p "choice=Select an option (1-2): "

if "%choice%"=="1" (
    if %current_state%==0 (
        echo Copilot is already disabled.
    ) else (
        echo Disabling Copilot...
        reg add "HKLM\SOFTWARE\AtlasOS\Copilot" /v state /t REG_DWORD /d 0 /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "0" /f > nul
        reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f > nul
        goto restartExplorer
    )
)

if "%choice%"=="2" (
    if %current_state%==1 (
        echo Copilot is already enabled.
    ) else (
        echo Enabling Copilot...
        reg add "HKLM\SOFTWARE\AtlasOS\Copilot" /v state /t REG_DWORD /d 1 /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "1" /f > nul
        reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f > nul 2>&1
        goto restartExplorer
    )
)

echo Invalid selection. Exiting...
exit /b

:restartExplorer
echo Restarting Explorer...
taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe
echo Changes applied successfully.
echo Press any key to exit...
pause > nul
exit /b
