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
set "AtlasElevatedArgument="
if defined silent set "AtlasElevatedArgument=/silent"
set "AtlasTitle=AtlasOS - Fix File Explorer Visual C++ Runtime Error"

"%AtlasNativeFltmc%" > nul 2>&1
if errorlevel 1 (
	rem This window only waits for the elevated one, which prints the rest of the run,
	rem then restarts File Explorer in this caller's own session.
	if not defined silent (
		echo %AtlasTitle%
		echo -----------------------------------------------------
		echo.
		echo Asking for administrator permission...
	)
	set "AtlasShellRefreshOwner=1"
	"%AtlasNativePowerShell%" -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $windows=[Environment]::GetFolderPath('Windows'); $system=[Environment]::GetFolderPath('System'); $launcher=[IO.Path]::Combine($windows,'AtlasModules','Toolbox','Scripts','Troubleshooting','Fix File Explorer Visual C++ Runtime Error.cmd'); $required=@($windows,[IO.Path]::Combine($windows,'AtlasModules'),[IO.Path]::Combine($windows,'AtlasModules','Toolbox'),[IO.Path]::Combine($windows,'AtlasModules','Toolbox','Scripts'),[IO.Path]::GetDirectoryName($launcher),$launcher); foreach($path in $required){if((-not [IO.File]::Exists($path) -and -not [IO.Directory]::Exists($path)) -or (([IO.File]::GetAttributes($path) -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw ('Required protected repair path is missing or a reparse point: '+$path)}}; $cmd=[IO.Path]::Combine($system,'cmd.exe'); $suffix=if($env:AtlasElevatedArgument){' '+$env:AtlasElevatedArgument}else{''}; $line='""{0}"{1}"' -f $launcher,$suffix; $start=@{FilePath=$cmd;ArgumentList=@('/d','/s','/c',$line);Verb='RunAs';WorkingDirectory=$system;PassThru=$true}; if($env:AtlasElevatedArgument){$start.WindowStyle='Hidden'}; $p=Start-Process @start; if($null -eq $p){exit 1}; $p.WaitForExit(); exit $p.ExitCode } catch { if($_.Exception -is [ComponentModel.Win32Exception] -and $_.Exception.NativeErrorCode -eq 1223){exit 1223}; Write-Error $_; exit 1 }" 2> nul
	if errorlevel 1 (
		set "AtlasShellRefreshOwner="
		if not defined silent (
			echo.
			echo Not applied: Fix File Explorer Visual C++ Runtime Error.
			echo Error: the administrator step did not complete. Its window shows the reason.
			echo.
			set /p "AtlasExit=Press Enter to exit. "
		)
		exit /b 1
	)
	set "AtlasShellRefreshOwner="
	set "shellRefreshScript=%AtlasWindowsRoot%\AtlasModules\Scripts\Operations\Invoke-AtlasUserShellRefresh.ps1"
	if not exist "%shellRefreshScript%" (
		echo User-session shell refresh helper not found: "%shellRefreshScript%"
		exit /b 1
	)
	if not defined silent echo Restarting File Explorer...
	"%AtlasNativePowerShell%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%shellRefreshScript%" -CurrentSession
	if errorlevel 1 (
		if not defined silent (
			echo Partly done: the repair is applied, but File Explorer could not be restarted safely in this session.
			echo Restart File Explorer, or sign out and back in, to see this change.
			echo.
			set /p "AtlasExit=Press Enter to exit. "
		)
		exit /b 1
	)
	if not defined silent echo File Explorer was restarted to apply this change.
	exit /b 0
)

if not defined silent (
	echo %AtlasTitle%
	echo -----------------------------------------------------
	echo Removes the legacy File Explorer search redirect that older Atlas builds used.
	echo It can fix blank Microsoft Visual C++ Runtime Library errors from explorer.exe.
	echo.
	set /p "AtlasContinue=Press Enter to continue, or Ctrl+C to cancel. "
	echo.
	echo Restoring the modern File Explorer search...
)

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
	if not defined silent (
		echo.
		echo Not applied: Fix File Explorer Visual C++ Runtime Error.
		echo Error: one or more machine-level File Explorer redirects could not be removed.
		echo.
		set /p "AtlasExit=Press Enter to exit. "
	)
	exit /b 1
)

if defined silent exit /b 0
echo.
echo Done: Fix File Explorer Visual C++ Runtime Error.
if not defined AtlasShellRefreshOwner echo Restart File Explorer, or sign out and back in, to see this change.
echo.
set /p "AtlasExit=Press Enter to exit. "
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
