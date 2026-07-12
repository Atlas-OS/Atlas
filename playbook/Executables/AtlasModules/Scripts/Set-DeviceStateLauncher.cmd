@echo off
verify other 2>nul
setlocal EnableExtensions DisableDelayedExpansion
if errorlevel 1 exit /b 1
cd /d "%__APPDIR__%"
if errorlevel 1 exit /b 1
for %%I in ("%__APPDIR__%..") do set "AtlasWindowsRoot=%%~fI"

set "launcherEnvironment=%AtlasWindowsRoot%\AtlasModules\Scripts\Internal\Initialize-PowerShellLauncherEnvironment.cmd"
if not exist "%launcherEnvironment%" (
    echo PowerShell launcher environment helper not found: "%launcherEnvironment%"
    exit /b 1
)
call "%launcherEnvironment%"
if errorlevel 1 exit /b 1

set "script=%AtlasWindowsRoot%\AtlasModules\Scripts\Internal\Set-DeviceState.ps1"
if not exist "%script%" (
    echo Script not found: "%script%"
    exit /b 1
)

"%__APPDIR__%fltmc.exe" > nul 2>&1
if errorlevel 1 (
    echo You need to run this script as an administrator.
    exit /b 1
)

if /i not "%~1"=="-Silent" goto unsupportedArguments
if /i "%~2"=="-Enable" goto enableDevice
if /i "%~2"=="-Devices" goto disableDevice
goto unsupportedArguments

:enableDevice
if /i not "%~3"=="-Devices" goto unsupportedArguments
if "%~4"=="" goto unsupportedArguments
if not "%~5"=="" goto unsupportedArguments
"%__APPDIR__%WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%script%" -Silent -Enable -AllowNoMatch -Devices "%~4"
if errorlevel 1 exit /b
exit /b 0

:disableDevice
if "%~3"=="" goto unsupportedArguments
if not "%~4"=="" goto unsupportedArguments
"%__APPDIR__%WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%script%" -Silent -AllowNoMatch -Devices "%~3"
if errorlevel 1 exit /b
exit /b 0

:unsupportedArguments
echo Unsupported Set-DeviceState launcher arguments.
exit /b 2
