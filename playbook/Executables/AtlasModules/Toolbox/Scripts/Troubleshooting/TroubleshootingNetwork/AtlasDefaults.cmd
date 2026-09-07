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

set "silent="
if "%~1"=="" goto argumentsValidated
if /i not "%~1"=="/silent" goto unsupportedArguments
if not "%~2"=="" goto unsupportedArguments
set "silent=1"

:argumentsValidated
set "networkScript=%AtlasWindowsRoot%\AtlasModules\Scripts\Entry\Set-NetworkDefaults.ps1"
if not exist "%networkScript%" (
	echo Network defaults helper not found: "%networkScript%"
	exit /b 1
)

set "AtlasElevatedLauncher=%AtlasWindowsRoot%\AtlasModules\Toolbox\Scripts\Troubleshooting\TroubleshootingNetwork\AtlasDefaults.cmd"
if not exist "%AtlasElevatedLauncher%" (
	echo Canonical network launcher not found: "%AtlasElevatedLauncher%"
	exit /b 1
)
set "AtlasElevatedArgument="
if defined silent set "AtlasElevatedArgument=/silent"

"%AtlasNativeFltmc%" > nul 2>&1
if errorlevel 1 (
	echo AtlasOS - Reset Network to Atlas Default
	echo ----------------------------------------
	echo.
	echo Asking for administrator permission...
	"%AtlasNativePowerShell%" -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $cmd=$env:AtlasNativeCommandHost; if(-not [IO.File]::Exists($cmd)){throw 'Native command host not found.'}; $suffix=if($env:AtlasElevatedArgument){' /silent'}else{''}; $line='""{0}"{1}"' -f $env:AtlasElevatedLauncher,$suffix; $p=Start-Process -FilePath $cmd -ArgumentList @('/d','/s','/c',$line) -Verb RunAs -WorkingDirectory $env:AtlasNativeSystemDirectory -WindowStyle $(if($env:AtlasElevatedArgument){'Hidden'}else{'Normal'}) -Wait -PassThru; if($null -eq $p){exit 1}; exit $p.ExitCode } catch { if($_.Exception -is [ComponentModel.Win32Exception] -and $_.Exception.NativeErrorCode -eq 1223){exit 1223}; Write-Error $_; exit 1 }" 2> nul
	if errorlevel 0 (
		if errorlevel 1 exit /b
	) else (
		exit /b 1
	)
	exit /b 0
)

if not defined silent (
	echo AtlasOS - Reset Network to Atlas Default
	echo ----------------------------------------
	echo.
	echo Applying the Atlas network adapter defaults...
)
"%AtlasNativePowerShell%" -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "%networkScript%" -Mode Atlas
if errorlevel 0 (
	if errorlevel 1 exit /b
) else (
	exit /b 1
)
if defined silent exit /b 0

echo.
echo Done: Reset Network to Atlas Default.
echo Restart recommended: restart Windows to finish applying this change.
echo.
set /p "AtlasExit=Press Enter to exit. "
exit /b 0

:unsupportedArguments
echo Unsupported Atlas network-default launcher arguments.
exit /b 2
