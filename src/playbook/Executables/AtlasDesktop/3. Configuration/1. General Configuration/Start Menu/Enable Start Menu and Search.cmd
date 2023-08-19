@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Rename start menu
cd !windir!\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy
ren StartMenuExperienceHost.exee StartMenuExperienceHost.exe

:: Rename search
cd !windir!\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy
ren SearchApp.exee SearchApp.exe

:: Search icon
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe > nul 2>&1

echo Finished, please reboot your device for changes to apply.
pause
exit /b