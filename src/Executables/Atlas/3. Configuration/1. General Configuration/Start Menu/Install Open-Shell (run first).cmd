@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

if exist "!windir!\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe" goto existOS
if exist "!windir!\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe" goto existOS
goto skipRM

:existOS
cls & set /P c="It appears search and start are installed, would you like to disable them also? [Y/N]? "
if /I "!c!" == "Y" goto rmSSOS
if /I "!c!" == "N" goto skipRM

:rmSSOS
:: Rename start menu
chdir /d !windir!\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy

:OSrestartStart
taskkill /f /im StartMenuExperienceHost* > nul 2>&1
ren StartMenuExperienceHost.exe StartMenuExperienceHost.exee

:: Loop if it fails to rename the first time
if exist "!windir!\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe" goto OSrestartStart

:: Rename search
chdir /d !windir!\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy

:OSrestartSearch
taskkill /f /im SearchApp* > nul 2>&1
ren SearchApp.exe SearchApp.exee

:: Loop if it fails to rename the first time
if exist "!windir!\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe" goto OSrestartSearch

:: Search icon
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe > nul 2>&1

:skipRM
echo]

:: Download Open-Shell
for /f "delims=" %%a in ('PowerShell "(Invoke-RestMethod -Uri "https://api.github.com/repos/Open-Shell/Open-Shell-Menu/releases/latest").assets.browser_download_url | findstr Setup"') do (
	curl -L --output !TEMP!\Open-Shell.exe %%a
)

echo Open-Shell is installing...
"!TEMP!\Open-Shell.exe" /qn ADDLOCAL=StartMenu

:: Download Fluent Metro theme
for /f "delims=" %%a in ('PowerShell "(Invoke-RestMethod -Uri "https://api.github.com/repos/bonzibudd/Fluent-Metro/releases/latest").assets.browser_download_url') do (
	curl -L --output !TEMP!\skin.zip %%a
)

PowerShell -NoP -C "Expand-Archive '!TEMP!\skin.zip' -DestinationPath 'C:\Program Files\Open-Shell\Skins'"

del /f /q !TEMP!\Open-Shell.exe > nul 2>&1
del /f /q !TEMP!\skin.zip > nul 2>&1

taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe

echo Finished, changes have been applied.
pause
exit /b