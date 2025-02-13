@echo off
set "settingName=SleepStudy"
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

reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

for %%a in (
    "Microsoft-Windows-SleepStudy/Diagnostic"
    "Microsoft-Windows-Kernel-Processor-Power/Diagnostic"
    "Microsoft-Windows-UserModePowerService/Diagnostic"
) do (
    wevtutil sl "%%~a" /q:true > nul
)

schtasks /change /tn "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /enable > nul

echo.
echo Sleep Study has been enabled.
echo Press any key to exit...
pause > nul
exit /b
