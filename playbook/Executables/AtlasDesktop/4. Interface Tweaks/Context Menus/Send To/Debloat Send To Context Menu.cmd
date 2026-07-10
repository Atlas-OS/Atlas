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

set "script=%AtlasWindowsRoot%\AtlasModules\Scripts\Internal\Set-SendToContextMenu.ps1"
if not exist "%script%" (
    echo Script not found: "%script%"
    exit /b 1
)

if "%~1"=="" goto invokeInteractive
if /i "%~1"=="-DebloatDefaults" goto invokeDefaults
goto unsupportedArgument

:invokeInteractive
if not "%~2"=="" goto unsupportedArgument
"%__APPDIR__%WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%script%"
if errorlevel 1 exit /b
exit /b 0

:invokeDefaults
if not "%~2"=="" goto unsupportedArgument
"%__APPDIR__%WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%script%" -DebloatDefaults
if errorlevel 1 exit /b
exit /b 0

:unsupportedArgument
echo Unsupported Send-To launcher argument.
exit /b 2
