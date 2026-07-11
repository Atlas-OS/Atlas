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

if not "%~2"=="" exit /b 87
set "AtlasResetSilent="
if "%~1"=="" goto AtlasResetRun
if /i "%~1"=="/silent" (
    set "AtlasResetSilent=-Silent"
    goto AtlasResetRun
)
exit /b 87

:AtlasResetRun
"%AtlasNativePowerShell%" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%AtlasWindowsRoot%\AtlasModules\Scripts\Invoke-AtlasResetServices.ps1" %AtlasResetSilent%
if errorlevel 0 (
    if errorlevel 1 exit /b
) else (
    exit /b 1
)
exit /b 0
