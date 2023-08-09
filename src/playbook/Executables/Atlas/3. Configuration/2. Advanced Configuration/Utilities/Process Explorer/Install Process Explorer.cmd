@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

ping -n 1 -4 www.example.com | find "time=" > nul 2>&1
if !errorlevel! == 1 (
	echo You must have an internet connection to use this script.
	pause
	exit /b 1
)

:: Download and install Process Explorer
choco install procexp -y --force --allow-empty-checksums

:: Create the shortcut
PowerShell -NoP -C "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut("""C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Process Explorer.lnk"""); $Shortcut.TargetPath = """$env:WinDir\AtlasModules\Apps\procexp.exe"""; $Shortcut.Save()"
if !errorlevel! == 1 (
	echo Process Explorer shortcut could not be created in the start menu^^!
)

:: Run Process Explorer always on top and allow only one instance
reg add "HKCU\SOFTWARE\Sysinternals\Process Explorer" /v "AlwaysOntop" /t REG_DWORD /d "1" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Sysinternals\Process Explorer" /v "OneInstance" /t REG_DWORD /d "1" /f > nul 2>&1

call setSvc.cmd pcw 4
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /t REG_SZ /d "C:\ProgramData\chocolatey\lib\procexp\tools\procexp64.exe" /f > nul 2>&1

echo Finished, changes have been applied.
pause
exit /b