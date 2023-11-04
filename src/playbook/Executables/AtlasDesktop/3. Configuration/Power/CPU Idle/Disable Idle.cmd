@echo off

:: Check if hyper threading is enabled
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfCores /value') do set "PHYSICAL_CORES=%%a"
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfLogicalProcessors /value') do set "LOGICAL_CORES=%%a"
if "%LOGICAL_CORES%" GTR "%PHYSICAL_CORES%" goto :hyperThreading

echo This forces your CPU to work at its maximum speed always, ensure you have good cooling.
echo]
echo Task Manager will display CPU usage as 100%% always, due to how Task Manager calculates CPU percentage.
echo It does not occur in other tools such as Process Explorer, System Informer or Process Hacker.
echo]
pause
cls
powercfg /setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 1
powercfg /setactive scheme_current

echo Finished, changes have been applied.
pause
exit /b

:hyperThreading
:: set ANSI escape characters
cd /d "%~dp0"
for /f %%A in ('forfiles /m "%~nx0" /c "cmd /c echo 0x1B"') do set "ESC=%%A"

title HT/SMT Detected - Atlas

mode con: cols=46 lines=13
chcp 65001 > nul
echo]
echo %ESC%[32m         Hyper Threading/SMT Detected
echo   ──────────────────────────────────────────%ESC%[0m
echo   You %ESC%[1mshould not disable idle states %ESC%[0mwhen
echo   this feature is enabled as it makes the
echo   overall CPU performance much worse.
echo]
echo   It can be disabled by using BIOS.
echo   Instead of disabling idle, consider 
echo   disabling C-states.
echo]
echo            %ESC%[1m%ESC%[33mPress any key to exit...      %ESC%[?25l
pause > nul
exit /b 1