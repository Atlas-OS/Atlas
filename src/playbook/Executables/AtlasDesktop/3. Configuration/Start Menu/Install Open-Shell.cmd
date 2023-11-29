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
echo Checking if WinGet exists...
call "%windir%\AtlasModules\Scripts\wingetCheck.cmd"
if %ERRORLEVEL% NEQ 0 exit /b 1

echo Downloading Open Shell...
echo]

:: Download and install Open-Shell
winget install -e --id Open-Shell.Open-Shell-Menu --override "/qn ADDLOCAL=StartMenu" -h --accept-source-agreements --accept-package-agreements --force > nul
if %ERRORLEVEL% NEQ 0 (
    echo error: Open-Shell installation with WinGet failed.
    pause
    exit /b 1
)

:: Download Fluent Metro theme
for /f tokens^=^4^ delims^=^" %%a in ('curl -L# -m 60 "https://api.github.com/repos/bonzibudd/Fluent-Metro/releases/latest" ^| find "browser_download_url"') do (
	set "fluentMetro=%%a"
)

curl -L -m 60 --output "%TEMP%\skin.zip" %fluentMetro% > nul 2>&1 || goto fluentError
PowerShell -NoP -C "Expand-Archive '%TEMP%\skin.zip' -DestinationPath '%ProgramFiles%\Open-Shell\Skins'" > nul 2>&1 || goto fluentError

:finish
del /f /q %TEMP%\Open-Shell.exe > nul 2>&1
del /f /q %TEMP%\skin.zip > nul 2>&1

taskkill /f /im explorer.exe > nul 2>&1
start explorer.exe

echo]
echo Finished, changes have been applied.
pause
exit /b

:fluentError
echo error: failed downloading the Fluent Metro Theme! GitHub might be blocked, Open-Shell will still function...
goto finish