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

set "assocScript=%AtlasWindowsRoot%\AtlasModules\Scripts\Internal\Set-FileAssociations.ps1"
if not exist "%assocScript%" (
    echo Set-FileAssociations.ps1 not found: "%assocScript%"
    exit /b 1
)

if not "%~2"=="" goto unsupportedArguments
if "%~1"=="" goto profileBase
if /i "%~1"=="Microsoft Edge" goto profileEdge
if /i "%~1"=="Brave" goto profileBrave
if /i "%~1"=="LibreWolf" goto profileLibreWolf
if /i "%~1"=="Firefox" goto profileFirefox
if /i "%~1"=="Google Chrome" goto profileChrome
goto unsupportedArguments

:profileBase
set "profile=Base"
goto profileSelected

:profileEdge
set "profile=Microsoft Edge"
goto profileSelected

:profileBrave
set "profile=Brave"
goto profileSelected

:profileLibreWolf
set "profile=LibreWolf"
goto profileSelected

:profileFirefox
set "profile=Firefox"
goto profileSelected

:profileChrome
set "profile=Google Chrome"

:profileSelected
set "powershellPath=%AtlasWindowsRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%powershellPath%" (
    echo Protected Windows PowerShell was not found: "%powershellPath%"
    exit /b 1
)

"%powershellPath%" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%assocScript%" -AssociationProfile "%profile%"
if errorlevel 1 exit /b
exit /b 0

:unsupportedArguments
echo Unsupported file-association launcher arguments.
exit /b 2
