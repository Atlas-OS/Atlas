@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f > nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects\{2F5183E9-4A32-40DD-9639-F9FAF80C79F4}Machine\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f > nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /f > nul 2>&1

echo Finished, please reboot your device for changes to apply.
pause
exit /b