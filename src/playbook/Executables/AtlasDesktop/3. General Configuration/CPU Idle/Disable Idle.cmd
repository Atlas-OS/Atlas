@echo off
set "settingName=CpuIdle"
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

:: Check if hyper threading is enabled
powershell -NonI -NoP -C "Get-CimInstance Win32_Processor | Foreach-Object { if ([int]$_.NumberOfLogicalProcessors -gt [int]$_.NumberOfCores) { exit 262 } }"
if "%errorlevel%"=="262" goto :hyperThreading

if "%~1" neq "/silent" (
    echo This forces your CPU to work at its maximum speed always, ensure you have good cooling.
    echo.
    echo Task Manager will display CPU usage as 100%% always, due to how Task Manager calculates CPU percentage.
    echo It does not occur in other tools such as Process Explorer, System Informer or Process Hacker.
    echo.
    pause
    cls
)

reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

powercfg /setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 1
powercfg /setactive scheme_current

if "%~1"=="/silent" exit /b

echo Finished, changes have been applied.
pause
exit /b

:hyperThreading
:: Hyper threading Detected Warning
cd /d "%~dp0"
for /f %%a in ('forfiles /m "%~nx0" /c "cmd /c echo 0x1B"') do set "ESC=%%a"
chcp 65001 > nul

title HT/SMT Detected - Atlas
mode con: cols=46 lines=13

echo.
echo %ESC%[32m         Hyper Threading/SMT Detected
echo   ──────────────────────────────────────────%ESC%[0m
echo   You %ESC%[1mshould not disable idle states %ESC%[0mwhen
echo   this feature is enabled as it makes the
echo   overall CPU performance much worse.
echo.
echo   It can be disabled by using BIOS.
echo   Instead of disabling idle, consider 
echo   disabling C-states in BIOS.
echo.
echo            %ESC%[1m%ESC%[33mPress any key to exit...      %ESC%[?25l

pause > nul
exit /b 1
