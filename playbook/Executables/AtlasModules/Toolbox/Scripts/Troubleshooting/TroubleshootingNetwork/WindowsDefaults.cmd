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

if not "%~1"=="" goto unsupportedArguments

set "networkScript=%AtlasWindowsRoot%\AtlasModules\Scripts\Internal\Set-NetworkDefaults.ps1"
if not exist "%networkScript%" (
	echo Network defaults helper not found: "%networkScript%"
	exit /b 1
)

set "AtlasElevatedLauncher=%AtlasWindowsRoot%\AtlasModules\Toolbox\Scripts\Troubleshooting\TroubleshootingNetwork\WindowsDefaults.cmd"
if not exist "%AtlasElevatedLauncher%" (
	echo Canonical network launcher not found: "%AtlasElevatedLauncher%"
	exit /b 1
)

"%AtlasNativeFltmc%" > nul 2>&1
if errorlevel 1 (
	echo Administrator privileges are required.
	"%AtlasNativePowerShell%" -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $cmd=$env:AtlasNativeCommandHost; if(-not [IO.File]::Exists($cmd)){throw 'Native command host not found.'}; $line='""{0}""' -f $env:AtlasElevatedLauncher; $p=Start-Process -FilePath $cmd -ArgumentList @('/d','/s','/c',$line) -Verb RunAs -WorkingDirectory $env:AtlasNativeSystemDirectory -Wait -PassThru; if($null -eq $p){exit 1}; exit $p.ExitCode } catch { if($_.Exception -is [ComponentModel.Win32Exception] -and $_.Exception.NativeErrorCode -eq 1223){exit 1223}; Write-Error $_; exit 1 }" 2> nul
	if errorlevel 0 (
		if errorlevel 1 exit /b
	) else (
		exit /b 1
	)
	exit /b 0
)

echo Resetting network settings to Windows defaults...
"%AtlasNativePowerShell%" -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "%networkScript%" -Mode Windows
if errorlevel 0 (
	if errorlevel 1 exit /b
) else (
	exit /b 1
)

echo Finished, please reboot your device for changes to apply.
pause
exit /b 0

:unsupportedArguments
echo The Windows network-default launcher does not accept arguments.
exit /b 2
