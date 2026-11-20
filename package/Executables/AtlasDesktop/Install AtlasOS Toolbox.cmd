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
set "script=%AtlasWindowsRoot%\AtlasModules\Scripts\Entry\Install-Toolbox.ps1"
if not exist "%script%" (
	echo Script not found.
	echo "%script%"
	exit /b 1
)

:: Capture one compatibility token as data; it is never passed on as command text.
set "AtlasLauncherArgument=%~1"

"%AtlasNativeFltmc%" > nul 2>&1 || (
    rem This window only waits for the elevated one, which prints the rest of the run.
    if not defined AtlasLauncherArgument (
        echo AtlasOS - Install AtlasOS Toolbox
        echo ---------------------------------
        echo.
        echo Asking for administrator permission...
    )
    "%AtlasNativePowerShell%" -NoLogo -NoProfile -Command "$a=$env:AtlasLauncherArgument;if($a -and $a -notin @('/silent','-silent')){exit 2};$s=[IO.Path]::Combine([Environment]::GetFolderPath('Windows'),'AtlasModules','Scripts','Entry','Install-Toolbox.ps1');$p=[Activator]::CreateInstance([Diagnostics.ProcessStartInfo]);$p.FileName=[IO.Path]::Combine([Environment]::GetFolderPath('System'),'WindowsPowerShell','v1.0','powershell.exe');$p.WorkingDirectory=[Environment]::GetFolderPath('System');$q=[char]34;$p.Arguments='-NoLogo -NoProfile -ExecutionPolicy Bypass -File '+$q+$s+$q+$(if($a){' -Silent'});$p.UseShellExecute=$true;$p.Verb='runas';try{$c=[Diagnostics.Process]::Start($p);if($null -eq $c){exit 1};$c.WaitForExit();exit $c.ExitCode}catch{if($_.Exception -is [ComponentModel.Win32Exception] -and $_.Exception.NativeErrorCode -eq 1223){exit 1223};exit 1}"
    if errorlevel 0 (
        if errorlevel 1 exit /b
    ) else (
        exit /b 1
    )
    exit /b 0
)

"%AtlasNativePowerShell%" -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%script%"
if errorlevel 0 (
    if errorlevel 1 exit /b
) else (
    exit /b 1
)
exit /b 0
