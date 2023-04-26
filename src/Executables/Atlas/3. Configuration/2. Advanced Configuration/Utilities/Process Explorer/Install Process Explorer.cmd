@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

ping -n 1 -4 1.1.1.1 | find "time=" > nul 2>&1
if !errorlevel! == 1 (
	echo You must have an internet connection to use this script.
	pause
	exit /b
)

curl.exe -L# "https://live.sysinternals.com/procexp.exe" -o "!windir!\AtlasModules\Apps\procexp.exe"
if !errorlevel! == 1 (
	echo Failed to download Process Explorer^^!
	pause
	exit /b 1
)

:: Create the shortcut
PowerShell -NoP -C "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut("""C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Process Explorer.lnk"""); $Shortcut.TargetPath = """$env:WinDir\AtlasModules\Apps\procexp.exe"""; $Shortcut.Save()"
if !errorlevel! == 1 (
	echo Process Explorer shortcut could not be created in the start menu^^!
)

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /t REG_SZ /d "!windir!\AtlasModules\Apps\procexp.exe" /f > nul 2>&1
call setSvc.cmd pcw 4

cls & echo Finished, changes have been applied.
pause
exit /b