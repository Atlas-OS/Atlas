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

where winget > nul 2>&1 || (
	echo You must have WinGet updated and installed to use this script.
	echo Press any key to exit...
	exit /b 1
)

winget uninstall -e --id Microsoft.Sysinternals.ProcessExplorer --force --purge --disable-interactivity --accept-source-agreements -h > nul

sc config pcw start=boot > nul
sc start pcw > nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /f > nul 2>&1
del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Process Explorer.lnk" > nul

echo Finished, all changes have been applied.
pause
exit /b
