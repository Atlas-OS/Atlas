@echo off
rem Shared body for every generated AtlasDesktop and Toolbox toggle launcher.
rem
rem A generated launcher is a two-line stub that calls this file with the toggle
rem name, the requested state (or - for a menu toggle), its own path, and any user
rem flags:
rem
rem     call "%__APPDIR__%..\AtlasModules\Scripts\Entry\Invoke-AtlasToggleLauncher.cmd" ^
rem         <Name> <State|-> "<launcher path>" [flags]
rem
rem The stub deliberately has no exit line: cmd.exe returns the last errorlevel from
rem this file as the process exit code, including negative values.
rem
rem Accepted flags are /silent, /quiet, /justcontext and /noaction, with either a
rem / or - prefix, case-insensitive. Anything else exits 87 before Windows PowerShell
rem starts, so no unvalidated token ever crosses the PowerShell boundary.
verify other 2>nul
setlocal EnableExtensions DisableDelayedExpansion
if errorlevel 1 exit /b 1
cd /d "%__APPDIR__%"
if errorlevel 1 exit /b 1
for %%I in ("%__APPDIR__%..") do set "AtlasWindowsRoot=%%~fI"
set "AtlasLauncherEnvironment=%AtlasWindowsRoot%\AtlasModules\Scripts\Entry\Initialize-PowerShellLauncherEnvironment.cmd"
if not exist "%AtlasLauncherEnvironment%" (
    echo PowerShell launcher environment helper not found: "%AtlasLauncherEnvironment%"
    exit /b 1
)
call "%AtlasLauncherEnvironment%"
if errorlevel 1 exit /b 1

set "AtlasToggleName=%~1"
set "AtlasToggleState=%~2"
set "AtlasLauncherPath=%~3"
if not defined AtlasToggleName exit /b 87
if not defined AtlasToggleState exit /b 87
if not defined AtlasLauncherPath exit /b 87
shift /1
shift /1
shift /1

set "AtlasLauncherSilent="
set "AtlasLauncherJustContext="
set "AtlasLauncherNoAction="
:parseArguments
if "%~1"=="" goto run
if /i "%~1"=="/silent" goto flagSilent
if /i "%~1"=="-silent" goto flagSilent
if /i "%~1"=="/quiet" goto flagSilent
if /i "%~1"=="-quiet" goto flagSilent
if /i "%~1"=="/justcontext" goto flagJustContext
if /i "%~1"=="-justcontext" goto flagJustContext
if /i "%~1"=="/noaction" goto flagNoAction
if /i "%~1"=="-noaction" goto flagNoAction
exit /b 87
:flagSilent
set "AtlasLauncherSilent=/silent"
shift /1
goto parseArguments
:flagJustContext
set "AtlasLauncherJustContext=/justcontext"
shift /1
goto parseArguments
:flagNoAction
set "AtlasLauncherNoAction=/noaction"
shift /1
goto parseArguments

:run
set "AtlasStateArgument="
if not "%AtlasToggleState%"=="-" set "AtlasStateArgument=-State "%AtlasToggleState%""
"%AtlasNativePowerShell%" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%AtlasWindowsRoot%\AtlasModules\Scripts\Entry\Invoke-Toggle.ps1" -Name "%AtlasToggleName%" %AtlasStateArgument% -LauncherPath "%AtlasLauncherPath%" %AtlasLauncherSilent% %AtlasLauncherJustContext% %AtlasLauncherNoAction%
if errorlevel 0 (
    if errorlevel 1 exit /b
) else (
    exit /b 1
)
exit /b 0
