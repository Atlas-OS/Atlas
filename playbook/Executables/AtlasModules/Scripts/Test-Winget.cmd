@echo off
verify other 2>nul
setlocal EnableExtensions DisableDelayedExpansion
if errorlevel 1 exit /b 1
cd /d "%__APPDIR__%"
if errorlevel 1 exit /b 1
for %%I in ("%__APPDIR__%..") do set "AtlasWindowsRoot=%%~fI"
set "SystemRoot=%AtlasWindowsRoot%"
set "windir=%AtlasWindowsRoot%"
set "ComSpec=%__APPDIR__%cmd.exe"
set "PATHEXT=.COM;.EXE;.BAT;.CMD"
set "PATH=%__APPDIR__%;%AtlasWindowsRoot%;%__APPDIR__%Wbem;%__APPDIR__%WindowsPowerShell\v1.0"
set "COR_ENABLE_PROFILING="
set "COR_PROFILER="
set "COR_PROFILER_PATH="
set "COR_PROFILER_PATH_32="
set "COR_PROFILER_PATH_64="
set "COR_PROFILER_PATH_ARM32="
set "COR_PROFILER_PATH_ARM64="
set "COR_PROFILER_PATH_X86="
set "COR_PROFILER_PATH_AMD64="
set "CORECLR_ENABLE_PROFILING="
set "CORECLR_PROFILER="
set "CORECLR_PROFILER_PATH="
set "CORECLR_PROFILER_PATH_32="
set "CORECLR_PROFILER_PATH_64="
set "CORECLR_PROFILER_PATH_ARM64="
set "CORECLR_PROFILER_PATH_X86="
set "DOTNET_STARTUP_HOOKS="
set "DOTNET_ADDITIONAL_DEPS="
set "DOTNET_SHARED_STORE="
set "DOTNET_ROOT="
set "DOTNET_ROOT_X86="
set "DOTNET_ROOT_X64="
set "DOTNET_ROOT_ARM64="
set "DOTNET_HOST_PATH="
set "DOTNET_BUNDLE_EXTRACT_BASE_DIR="
set "APPDOMAIN_MANAGER_ASM="
set "APPDOMAIN_MANAGER_TYPE="
set "APPDOMAIN_MANAGER_APP_CONFIG="
set "APPDOMAIN_MANAGER_INITIALIZATION_OPTIONS="
set "COMPLUS_APPDOMAINMANAGERASSEMBLY="
set "COMPLUS_APPDOMAINMANAGERTYPE="
set "COMPLUS_APPLICATIONMIGRATIONRUNTIMEACTIVATIONCONFIGPATH="
set "COMPLUS_INSTALLROOT="
set "COMPLUS_VERSION="
set "COMPLUS_TPALIST="
set "COMPLUS_JITNAME="
set "COMPLUS_JITPATH="
set "COMPLUS_ALTJIT="
set "COMPLUS_ALTJITNAME="
set "COMPLUS_ALTJITPATH="
set "PSModulePath="

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

"%__APPDIR__%WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Internal\Test-TrustedWinget.ps1" > nul 2>&1 || (
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
