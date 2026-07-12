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

set "edgeScript=%AtlasWindowsRoot%\AtlasModules\Scripts\Internal\Remove-Edge.ps1"
if not exist "%edgeScript%" (
    echo Edge script not found: "%edgeScript%"
    exit /b 1
)

if "%~1"=="" goto argumentsValidated
if /i "%~1"=="/edgeonly" goto validateSingleArgument
if /i "%~1"=="/webview" goto validateSingleArgument
if /i "%~1"=="/silent" goto validateSingleArgument
goto unsupportedArguments

:validateSingleArgument
if not "%~2"=="" goto unsupportedArguments

:argumentsValidated
set "AtlasProgramFilesX86="
for /f "tokens=2,*" %%A in ('"%__APPDIR__%reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion" /v "ProgramFilesDir ^(x86^)" 2^>nul') do (
    if /i "%%A"=="REG_SZ" set "AtlasProgramFilesX86=%%B"
)
if not defined AtlasProgramFilesX86 (
    echo Failed to resolve the protected 32-bit Program Files directory.
    exit /b 1
)
for %%I in ("%AtlasProgramFilesX86%") do set "AtlasProgramFilesX86=%%~fI"
if not exist "%AtlasProgramFilesX86%\" (
    echo Protected 32-bit Program Files directory not found: "%AtlasProgramFilesX86%"
    exit /b 1
)

set ___edge=0
if exist "%AtlasProgramFilesX86%\Microsoft\Edge\Application\msedge.exe" (
    set ___edge=1
    if /i "%~1"=="/edgeonly" exit /b 0
)
if /i "%~1"=="/webview" set ___edge=1

set "___dashes=-----------------------------------------------------------------------------------------------------"
echo %___dashes%

if %___edge% neq 0 (
    echo Updating Edge WebView 2...
    goto main
)

if /i not "%~1"=="/silent" (
    echo Microsoft Edge is required to use this script.
    if %___edge%==0 echo In the future, if you no longer want to use this feature, you can use the disable script and uninstall Edge.
    "%__APPDIR__%choice.exe" /c:yn /n /m "Would you like to install Edge? [Y/N] "
    if errorlevel 2 (
        echo]
        echo Press any key to exit...
        pause > nul
        exit /b 1
    )
) else (
    if %___edge%==0 (
        echo Edge is missing but silent mode is active. Exiting...
        exit /b 1
    )
)

:main
echo]
if %___edge%==0 (
	"%__APPDIR__%WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "%edgeScript%" -NonInteractive -InstallWebView -InstallEdge
) else (
	"%__APPDIR__%WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "%edgeScript%" -NonInteractive -InstallWebView
)

if errorlevel 1 exit /b

echo %___dashes%
exit /b 0

:unsupportedArguments
echo Unsupported Edge state launcher arguments.
exit /b 2
