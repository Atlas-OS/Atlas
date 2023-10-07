@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

if exist "%windir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy" goto error
if exist "%windir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy" goto error

goto main

:error
echo error: Start Menu and Search are already enabled.
echo Press any key to exit...
pause > nul
exit /b 1

:main
cd %windir%\SystemApps

:: Rename start menu
set "startName=Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy"
ren %startName%.old %startName%

:: Rename search
set "startName=Microsoft.Windows.Search_cw5n1h2txyewy"
ren %startName%.old %startName%

:: Search icon
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f > nul
taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe

echo Finished, please reboot your device for changes to apply.
pause
exit /b