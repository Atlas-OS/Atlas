@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

if exist "C:\Program Files\Open-Shell" goto existS
if exist "C:\Program Files (x86)\StartIsBack" goto existS
echo It seems neither Open-Shell nor StartIsBack are not installed. It is HIGHLY recommended to install one of these before running this due to the Start Menu being removed.
pause

:existS
set /P c="This will disable SearchApp and StartMenuExperienceHost, are you sure you want to continue [Y/N]? "
if /I "!c!" == "Y" goto continSS
if /I "!c!" == "N" exit /b
if /I "!c!" == "" echo No option selected - launch the script again. & pause & exit
:continSS
:: Rename start menu
chdir /d !windir!\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy

:restartStart
taskkill /f /im StartMenuExperienceHost* > nul 2>&1
ren StartMenuExperienceHost.exe StartMenuExperienceHost.exee

:: Loop if it fails to rename the first time
if exist "!windir!\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe" goto restartStart

:: Rename search
chdir /d !windir!\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy

:restartSearch
taskkill /f /im SearchApp* > nul 2>&1
ren SearchApp.exe SearchApp.exee

:: Loop if it fails to rename the first time
if exist "!windir!\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe" goto restartSearch

:: Search icon
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe > nul 2>&1

echo Finished, please reboot your device for changes to apply.
pause
exit /b