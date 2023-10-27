@echo off

fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	PowerShell Start -Verb RunAs '%0' 2> nul || (
		echo You must run this script as admin.
		exit /b 1
	)
	exit /b
)

:: Check if WinGet is functional or not
call "%windir%\AtlasModules\Scripts\wingetCheck.cmd"
if %errorlevel% NEQ 0 exit /b 1

cd %windir%\SystemApps
if exist "Microsoft.Windows.Search_cw5n1h2txyewy" goto existOS
if exist "Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy" goto existOS
goto skipRM

:existOS
cls & set /P c="It appears search and start are installed, would you like to disable them also? [Y/N]? "
if /I "%c%" == "Y" goto rmSSOS
if /I "%c%" == "N" goto skipRM

:rmSSOS
call "%windir%\AtlasDesktop\3. Configuration\Start Menu\Disable Start Menu and Search.cmd" /silent

:skipRM
echo]

:: Download and install Open-Shell
winget install -e --id Open-Shell.Open-Shell-Menu -h --accept-source-agreements --accept-package-agreements --force > nul
if %errorlevel% NEQ 0 (
    echo error: Open-Shell installation with WinGet failed.
    pause
    exit /b 1
)

:: Download Fluent Metro theme
for /f tokens^=^4^ delims^=^" %%a in ('curl -m 60 "https://api.github.com/repos/bonzibudd/Fluent-Metro/releases/latest" ^| find "browser_download_url"') do (
	set "fluentMetro=%%a"
)

curl -L -m 60 --output "%TEMP%\skin.zip" %fluentMetro% > nul 2>&1 || goto fluentError
powershell -NoP -C "Expand-Archive '%TEMP%\skin.zip' -DestinationPath '%ProgramFiles%\Open-Shell\Skins'" > nul 2>&1 || goto fluentError

:finish
del /f /q %TEMP%\Open-Shell.exe > nul 2>&1
del /f /q %TEMP%\skin.zip > nul 2>&1

taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe

echo Finished, changes have been applied.
pause
exit /b

:fluentError
echo error: failed downloading the Fluent Metro Theme! GitHub might be blocked, Open-Shell will still function...
goto finish