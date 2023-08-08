@echo off
setlocal EnableDelayedExpansion


:: Check if hyper threading is enabled
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfCores /value') do set PHYSICAL_CORES=%%a
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfLogicalProcessors /value') do set LOGICAL_CORES=%%a

if "%LOGICAL_CORES%" GTR "%PHYSICAL_CORES%" (
	call :hyperThreading
)

echo This will make your Task Manager display CPU usage as 100% (visual bug). It does not occur in Process Explorer.
powercfg /setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 1
powercfg /setactive scheme_current

echo Finished, changes have been applied.
pause
exit /b

:hyperThreading
mode con: cols=46 lines=14
chcp 65001 > nul
echo]
echo [32m           Hyper Threading Detected
echo   ──────────────────────────────────────────[0m
echo   Detected Hyper Threading feature enabled.
echo]
echo   You [1mshould not disable idle states [0mwhen
echo   this feature is enabled as it makes
echo   the single-threaded performance worse.
echo]
echo   It can be disabled by using BIOS or GRUB.
echo]
echo            [1m[33mPress any key to exit...      [?25l
pause > nul
exit /b 1