@echo off

fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	PowerShell Start -Verb RunAs '%0' 2> nul || (
		echo You must run this script as admin.
		pause & exit /b 1
	)
	exit /b
)

:: Check if WinGet is functional or not
call "%windir%\AtlasModules\Scripts\wingetCheck.cmd" /silent
if %ERRORLEVEL% NEQ 0 (
	echo info: WinGet is not functional, can't uninstall Process Explorer, reverting other changes anyways...
	goto otherChanges
)

winget uninstall -e --id Microsoft.Sysinternals.ProcessExplorer --force --purge --disable-interactivity --accept-source-agreements -h > nul
if %ERRORLEVEL% NEQ 0 echo info: Process Explorer uninstallation failed, reverting other changes anyways...

:otherChanges
sc config pcw start=boot > nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /f > nul 2>&1
del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Process Explorer.lnk" > nul

echo Finished, changes have been applied.
pause
exit /b
