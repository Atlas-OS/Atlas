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
set "script=%AtlasWindowsRoot%\AtlasModules\Scripts\Install-Toolbox.ps1"
if not exist "%script%" (
	echo Script not found.
	echo "%script%"
	exit /b 1
)

:: Capture one compatibility token as data, then clear every managed-runtime
:: loader input before the first PowerShell process starts. This prevents a
:: medium caller's profiler/startup hook from crossing the Atlas UAC prompt.
set "AtlasLauncherArgument=%~1"
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

"%__APPDIR__%fltmc.exe" > nul 2>&1 || (
    "%__APPDIR__%WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command "$a=$env:AtlasLauncherArgument;if($a -and $a -notin @('/silent','-silent')){exit 2};$s=[IO.Path]::Combine([Environment]::GetFolderPath('Windows'),'AtlasModules','Scripts','Install-Toolbox.ps1');$p=[Activator]::CreateInstance([Diagnostics.ProcessStartInfo]);$p.FileName=[IO.Path]::Combine([Environment]::GetFolderPath('System'),'WindowsPowerShell','v1.0','powershell.exe');$p.WorkingDirectory=[Environment]::GetFolderPath('System');$q=[char]34;$p.Arguments='-NoLogo -NoProfile -ExecutionPolicy Bypass -File '+$q+$s+$q+$(if($a){' -Silent'});$p.UseShellExecute=$true;$p.Verb='runas';try{$c=[Diagnostics.Process]::Start($p);if($null -eq $c){exit 1};$c.WaitForExit();exit $c.ExitCode}catch{if($_.Exception -is [ComponentModel.Win32Exception] -and $_.Exception.NativeErrorCode -eq 1223){exit 1223};exit 1}"
    if errorlevel 0 (
        if errorlevel 1 exit /b
    ) else (
        exit /b 1
    )
    exit /b 0
)

"%__APPDIR__%WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%script%"
if errorlevel 0 (
    if errorlevel 1 exit /b
) else (
    exit /b 1
)
exit /b 0
