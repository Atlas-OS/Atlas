@echo off
rem Runs the armed Safe Mode retry of Atlas packages that failed to install, or gives
rem it up with /discard. It lets the retry start from the bare Safe Mode command
rem prompt; CbsRetry.ps1 names it in every retry message.
verify other 2>nul
setlocal EnableExtensions DisableDelayedExpansion
if errorlevel 1 exit /b 1
cd /d "%__APPDIR__%"
if errorlevel 1 exit /b 1
for %%I in ("%__APPDIR__%..") do set "AtlasWindowsRoot=%%~fI"
set "launcherEnvironment=%AtlasWindowsRoot%\AtlasModules\Scripts\Entry\Initialize-PowerShellLauncherEnvironment.cmd"
if not exist "%launcherEnvironment%" (
    echo PowerShell launcher environment helper not found: "%launcherEnvironment%"
    exit /b 1
)
call "%launcherEnvironment%"
if errorlevel 1 exit /b 1

if not "%~2"=="" goto unsupportedArguments
set "AtlasCbsRetryMode=-Recover"
if "%~1"=="" goto AtlasCbsRetryRun
if /i "%~1"=="/discard" (
    set "AtlasCbsRetryMode=-Discard"
    goto AtlasCbsRetryRun
)
goto unsupportedArguments

:AtlasCbsRetryRun
"%AtlasNativePowerShell%" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%AtlasWindowsRoot%\AtlasModules\Scripts\Operations\CbsRetry.ps1" %AtlasCbsRetryMode%
if errorlevel 0 (
    if errorlevel 1 exit /b
) else (
    exit /b 1
)
rem CbsRetry.ps1 set the PROMPT this window opened with to name the retry; once the
rem retry is done or given up, the window goes back to the default prompt.
if "%PROMPT:~0,30%"=="Atlas: Safe Mode package retry" (endlocal & prompt) else endlocal
exit /b 0

:unsupportedArguments
echo Run this without arguments to retry the packages, or with /discard to give up the retry.
exit /b 87
