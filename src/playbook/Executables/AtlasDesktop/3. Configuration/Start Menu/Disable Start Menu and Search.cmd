@echo off

if "%~1" == "/silent" goto start

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

if exist "%windir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy" goto existS
if exist "%windir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy" goto existS

:error
echo error: Start Menu and Search are already disabled.
echo Press any key to exit...
pause > nul
exit /b 1

:existS
if exist "%ProgramFiles%\Open-Shell" goto main
if exist "%ProgramFiles(x86)%\StartIsBack" goto main
if exist "%LOCALAPPDATA%\StartAllBack" goto main
echo It seems that no Start Menu replacement has been installed. It is recommended to install one of these before running this due to the Start Menu being removed.
pause

:main
set /P c="This will disable SearchApp and StartMenuExperienceHost, are you sure you want to continue [Y/N]? "
if /I "%c%" == "Y" cd %windir%\SystemApps & goto start
if /I "%c%" == "N" exit /b
if /I "%c%" == "" echo No option selected - launch the script again. & pause & exit /b 1

:start
set "startName=Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy"
taskkill /f /im StartMenuExperienceHost* > nul 2>&1
ren %startName% %startName%.old > nul 2>&1

:: Loop if it fails to rename the first time
if exist "%windir%\SystemApps\%startName%" goto start

:search
set "searchName=Microsoft.Windows.Search_cw5n1h2txyewy"
taskkill /f /im SearchApp* > nul 2>&1
ren %searchName% %searchName%.old > nul 2>&1

:: Loop if it fails to rename the first time
if exist "%windir%\SystemApps\%searchName%" goto search

:: Search icon
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f > nul
taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe

if "%~1" == "/silent" exit /b

echo Finished, please reboot your device for changes to apply.
pause
exit /b