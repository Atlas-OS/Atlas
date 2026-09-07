@echo off
rem This file is called from Atlas launchers after they have anchored themselves to
rem the protected Windows command host. Keep it free of setlocal: the sanitized
rem environment must remain in the caller before Windows PowerShell starts.
if not defined AtlasWindowsRoot exit /b 1

rem __APPDIR__ identifies the running command image directory but does not attest
rem its ACL. These exact forms reject unknown hosts; callers must still start this
rem helper from the protected Windows command host rather than a copied fake tree.
set "AtlasNativeSystemDirectory=%AtlasWindowsRoot%\System32"
set "AtlasNativeLaunchDirectory="
set "AtlasNativeCommandHost=%AtlasWindowsRoot%\System32\cmd.exe"
set "AtlasNativePowerShell="
set "AtlasNativeFltmc="
if /i "%__APPDIR__%"=="%AtlasWindowsRoot%\System32\" goto atlasNativeHost
if /i "%__APPDIR__%"=="%AtlasWindowsRoot%\SysWOW64\" goto atlasWow64Host
if /i "%__APPDIR__%"=="%AtlasWindowsRoot%\SysArm32\" goto atlasWow64Host
exit /b 1

:atlasNativeHost
set "AtlasNativeLaunchDirectory=%AtlasNativeSystemDirectory%"
goto atlasHostSelected

:atlasWow64Host
rem Sysnative is only a launch alias for a WOW64 parent. The native child must
rem inherit canonical System32 values because Sysnative is absent in that child.
set "AtlasNativeLaunchDirectory=%AtlasWindowsRoot%\Sysnative"

:atlasHostSelected
set "AtlasNativePowerShell=%AtlasNativeLaunchDirectory%\WindowsPowerShell\v1.0\powershell.exe"
set "AtlasNativeFltmc=%AtlasNativeLaunchDirectory%\fltmc.exe"
if not exist "%AtlasNativeLaunchDirectory%\cmd.exe" exit /b 1
if not exist "%AtlasNativePowerShell%" exit /b 1
if not exist "%AtlasNativeLaunchDirectory%\WindowsPowerShell\v1.0\Modules\" exit /b 1
set "SystemRoot=%AtlasWindowsRoot%"
set "windir=%AtlasWindowsRoot%"
set "ComSpec=%AtlasNativeCommandHost%"
set "PATHEXT=.COM;.EXE;.BAT;.CMD"
set "PATH=%AtlasNativeSystemDirectory%;%AtlasWindowsRoot%;%AtlasNativeSystemDirectory%\Wbem;%AtlasNativeSystemDirectory%\WindowsPowerShell\v1.0"
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
rem Keep inbox module autoload available without inheriting user-writable module roots.
set "PSModulePath=%AtlasNativeSystemDirectory%\WindowsPowerShell\v1.0\Modules"
exit /b 0
