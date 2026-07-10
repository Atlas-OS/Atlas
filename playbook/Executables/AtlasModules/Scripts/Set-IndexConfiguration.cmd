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

set "script=%AtlasWindowsRoot%\AtlasModules\Scripts\Internal\Set-IndexConfiguration.ps1"
if not exist "%script%" (
    echo Index configuration script not found: "%script%"
    exit /b 1
)

set "operation="
set "indexPath="
if /i "%~1"=="/include" goto selectInclude
if /i "%~1"=="/exclude" goto selectExclude
if /i "%~1"=="/cleanpolicies" goto selectCleanPolicies
if /i "%~1"=="/start" goto selectStart
if /i "%~1"=="/stop" goto selectStop
goto unsupportedArguments

:selectInclude
if "%~2"=="" goto unsupportedArguments
if not "%~3"=="" goto unsupportedArguments
set "operation=Include"
set "indexPath=%~2"
goto validateAdministrator

:selectExclude
if "%~2"=="" goto unsupportedArguments
if not "%~3"=="" goto unsupportedArguments
set "operation=Exclude"
set "indexPath=%~2"
goto validateAdministrator

:selectCleanPolicies
if not "%~2"=="" goto unsupportedArguments
set "operation=CleanPolicies"
goto validateAdministrator

:selectStart
if not "%~2"=="" goto unsupportedArguments
set "operation=Start"
goto validateAdministrator

:selectStop
if not "%~2"=="" goto unsupportedArguments
set "operation=Stop"

:validateAdministrator
"%AtlasNativeFltmc%" > nul 2>&1
if errorlevel 1 goto administratorRequired
if defined indexPath goto invokeWithPath
goto invokeWithoutPath

:invokeWithPath
"%AtlasNativePowerShell%" -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "%script%" -Operation "%operation%" -IndexPath "%indexPath%"
if errorlevel 0 (
    if errorlevel 1 exit /b
) else (
    exit /b 1
)
exit /b 0

:invokeWithoutPath
"%AtlasNativePowerShell%" -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "%script%" -Operation "%operation%"
if errorlevel 0 (
    if errorlevel 1 exit /b
) else (
    exit /b 1
)
exit /b 0

:administratorRequired
echo You must run this script as admin.
exit /b 1

:unsupportedArguments
echo You must use exactly one supported operation:
echo ---------------------------------------------
echo /include [full folder path]
echo /exclude [full folder path]
echo /cleanpolicies
echo /start
echo /stop
exit /b 2
