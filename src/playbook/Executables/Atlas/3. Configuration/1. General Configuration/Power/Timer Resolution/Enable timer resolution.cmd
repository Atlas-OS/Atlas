@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

echo Credit to @amitxv on GitHub for the project used that forces timer resolution on Windows 11!
echo Before running this, please see the Atlas documentation, linked in the folder.
echo]
pause & cls

schtasks /create /tn "Force Timer Resolution" /xml "%windir%\AtlasModules\Other\Force Timer Resolution.xml" /f > nul
schtasks /run /tn "Force Timer Resolution" > nul

echo Finished, changes have been applied.
pause
exit /b