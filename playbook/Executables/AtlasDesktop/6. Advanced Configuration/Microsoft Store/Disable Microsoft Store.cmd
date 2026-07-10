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
set "AtlasLauncherSilent="
set "AtlasLauncherJustContext="
set "AtlasLauncherNoAction="
:AtlasLauncherParseArguments
if "%~1"=="" goto AtlasLauncherRun
if /i "%~1"=="/silent" goto AtlasLauncherFlagSilent
if /i "%~1"=="-silent" goto AtlasLauncherFlagSilent
if /i "%~1"=="/quiet" goto AtlasLauncherFlagSilent
if /i "%~1"=="-quiet" goto AtlasLauncherFlagSilent
if /i "%~1"=="/justcontext" goto AtlasLauncherFlagJustContext
if /i "%~1"=="-justcontext" goto AtlasLauncherFlagJustContext
if /i "%~1"=="/noaction" goto AtlasLauncherFlagNoAction
if /i "%~1"=="-noaction" goto AtlasLauncherFlagNoAction
exit /b 87
:AtlasLauncherFlagSilent
set "AtlasLauncherSilent=/silent"
shift /1
goto AtlasLauncherParseArguments
:AtlasLauncherFlagJustContext
set "AtlasLauncherJustContext=/justcontext"
shift /1
goto AtlasLauncherParseArguments
:AtlasLauncherFlagNoAction
set "AtlasLauncherNoAction=/noaction"
shift /1
goto AtlasLauncherParseArguments
:AtlasLauncherRun
"%AtlasNativePowerShell%" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%AtlasWindowsRoot%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name "MicrosoftStore" -State "Disable" -LauncherPath "%~f0" %AtlasLauncherSilent% %AtlasLauncherJustContext% %AtlasLauncherNoAction%
if errorlevel 0 (
    if errorlevel 1 exit /b
) else (
    exit /b 1
)
exit /b 0
