@echo off
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

set "dashes=-----------------------------------------------------------------------------------------------------"
set "silent="
set "nodashes="
:parseArguments
if "%~1"=="" goto argumentsParsed
if /i "%~1"=="/silent" goto silentArgument
if /i "%~1"=="/nodashes" goto nodashesArgument
exit /b 2

:silentArgument
set "silent=true"
goto nextArgument

:nodashesArgument
set "nodashes=true"

:nextArgument
shift /1
goto parseArguments

:argumentsParsed

if not defined silent (if not defined nodashes echo %dashes%)

:main
if not defined silent echo Checking for WinGet...

"%AtlasNativePowerShell%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-TrustedWinget.ps1" > nul 2>&1 || (
    if defined silent exit /b 1
    set "action=update"
    set "uri=ms-windows-store://downloadsandupdates"
    goto error
)

if not defined silent (
    if not defined nodashes (
        echo %dashes%
        echo]
    )
)

exit /b 0

:error
cls
echo You need the latest version of WinGet to use this script.
echo WinGet is included with 'App Installer' on the Microsoft Store, it's also on GitHub.
echo]
"%__APPDIR__%choice.exe" /c:yn /n /m "Would you like to open the Microsoft Store to %action% it? [Y/N] "
if errorlevel 2 exit /b 2
if errorlevel 1 start "" "%uri%"
exit /b 2
