@echo off
setlocal EnableDelayedExpansion

fltmc >nul 2>&1 || (
	echo Administrator privileges are required.
	PowerShell Start -Verb RunAs '%0' 2> nul || (
		echo You must run this script as admin.
		pause & exit /b 1
	)
	exit /b
)

ping -n 1 -4 www.example.com | find "time=" > nul 2>&1
if !errorlevel! == 1 (
	echo You must have an internet connection to use this script.
	pause
	exit /b 1
)

where winget > nul 2>&1 || (
	echo You must have WinGet updated and installed to use this script.
	echo Press any key to exit...
	exit /b 1
)

echo Installing Process Explorer...
winget install -e --id Microsoft.Sysinternals.ProcessExplorer --uninstall-previous -l "%windir%\AtlasModules\Apps\ProcessExplorer" -h --accept-source-agreements --accept-package-agreements --force --disable-interactivity > nul
if !errorlevel! NEQ 0 (
    echo Error: Process Explorer installation failed.
    pause
    exit /b 1
)

echo Creating the Start menu shortcut...
PowerShell -NoP -C "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut("""$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Process Explorer.lnk"""); $Shortcut.TargetPath = """$env:WinDir\AtlasModules\Apps\ProcessExplorer\procexp.exe"""; $Shortcut.Save()" > nul
if not errorlevel 0 (
	echo Process Explorer shortcut could not be created in the start menu^^!
)

echo Configuring Process Explorer...
:: Run Process Explorer only in one instance
reg add "HKCU\SOFTWARE\Sysinternals\Process Explorer" /v "OneInstance" /t REG_DWORD /d "1" /f > nul
sc config pcw start=disabled > nul
sc stop pcw > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /t REG_SZ /d "%windir%\AtlasModules\Apps\ProcessExplorer\procexp64.exe" /f > nul

echo]
echo Finished, changes have been applied.
pause
exit /b