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

set "silent="
if "%~1"=="" goto argumentsValidated
if /i not "%~1"=="/silent" goto unsupportedArguments
if not "%~2"=="" goto unsupportedArguments
set "silent=1"

:argumentsValidated
set "AtlasElevatedArgument="
if defined silent set "AtlasElevatedArgument=/silent"

"%AtlasNativeFltmc%" > nul 2>&1
if errorlevel 1 (
	echo Administrator privileges are required.
	set "AtlasShellRefreshOwner=1"
	"%AtlasNativePowerShell%" -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $windows=[Environment]::GetFolderPath('Windows'); $system=[Environment]::GetFolderPath('System'); $launcher=[IO.Path]::Combine($windows,'AtlasDesktop','9. Troubleshooting','Fix File Explorer Visual C++ Runtime Error.cmd'); $required=@($windows,[IO.Path]::Combine($windows,'AtlasDesktop'),[IO.Path]::GetDirectoryName($launcher),$launcher); foreach($path in $required){if((-not [IO.File]::Exists($path) -and -not [IO.Directory]::Exists($path)) -or (([IO.File]::GetAttributes($path) -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw ('Required protected repair path is missing or a reparse point: '+$path)}}; $cmd=[IO.Path]::Combine($system,'cmd.exe'); $suffix=if($env:AtlasElevatedArgument){' '+$env:AtlasElevatedArgument}else{''}; $line='""{0}"{1}"' -f $launcher,$suffix; $start=@{FilePath=$cmd;ArgumentList=@('/d','/s','/c',$line);Verb='RunAs';WorkingDirectory=$system;PassThru=$true}; if($env:AtlasElevatedArgument){$start.WindowStyle='Hidden'}; $p=Start-Process @start; if($null -eq $p){exit 1}; $p.WaitForExit(); exit $p.ExitCode } catch { if($_.Exception -is [ComponentModel.Win32Exception] -and $_.Exception.NativeErrorCode -eq 1223){exit 1223}; Write-Error $_; exit 1 }" 2> nul
	if errorlevel 1 (
		set "AtlasShellRefreshOwner="
		echo You must run this script as admin.
		exit /b 1
	)
	set "AtlasShellRefreshOwner="
	set "shellRefreshScript=%AtlasWindowsRoot%\AtlasModules\Scripts\Internal\Invoke-AtlasUserShellRefresh.ps1"
	if not exist "%shellRefreshScript%" (
		echo User-session shell refresh helper not found: "%shellRefreshScript%"
		exit /b 1
	)
	"%AtlasNativePowerShell%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%shellRefreshScript%" -CurrentSession
	if errorlevel 1 (
		echo The machine repair completed, but File Explorer could not be refreshed safely in this session.
		exit /b 1
	)
	exit /b 0
)

if not defined silent (
	echo This will remove the legacy File Explorer search redirect used by older Atlas builds.
	echo It can fix blank Microsoft Visual C++ Runtime Library errors from explorer.exe.
	echo]
	if /i not "%~1"=="/silent" pause
	cls
)

echo Restoring modern File Explorer search...
set "repairError="
call :deleteKey "HKLM\SOFTWARE\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs"
if errorlevel 1 set "repairError=1"
call :deleteKey "HKLM\SOFTWARE\Classes\WOW6432Node\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs"
if errorlevel 1 set "repairError=1"
call :deleteKey "HKLM\SOFTWARE\WOW6432Node\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs"
if errorlevel 1 set "repairError=1"
rem Do not traverse HKCU/HKU from this elevated deputy. User hives and registry
rem links are not a trusted machine boundary; only the fixed machine keys are repaired.
if defined repairError (
	echo Failed to remove one or more machine-level File Explorer redirects.
	if not defined silent pause
	exit /b 1
)

echo Machine repair finished.
if not defined AtlasShellRefreshOwner echo Restart File Explorer from a non-elevated session, or sign out and back in, to apply the repair.
if defined silent exit /b 0
if /i not "%~1"=="/silent" pause
exit /b 0

:unsupportedArguments
echo Unsupported File Explorer repair launcher arguments.
exit /b 2

:deleteKey
"%AtlasNativeSystemDirectory%\reg.exe" query "%~1" > nul 2>&1
if errorlevel 1 exit /b 0
"%AtlasNativeSystemDirectory%\reg.exe" delete "%~1" /f > nul 2>&1
if errorlevel 1 exit /b 1
"%AtlasNativeSystemDirectory%\reg.exe" query "%~1" > nul 2>&1
if not errorlevel 1 exit /b 1
exit /b 0
