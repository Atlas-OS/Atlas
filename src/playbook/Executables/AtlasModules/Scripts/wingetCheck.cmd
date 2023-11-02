@echo off
:: Simple script to check if WinGet is functional or not

ping -n 1 -4 www.microsoft.com > nul 2>&1
if %ERRORLEVEL% == 1 (
    if "%~1"=="/silent" exit /b 2
	echo You must have an internet connection to use this script.
	echo Press any key to exit...
	pause > nul
	exit /b 2
)

where winget > nul 2>&1 || (
    if "%~1"=="/silent" exit /b 1
    set "action=install"
    set "uri=ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
    goto :error
)
winget search "Microsoft Visual Studio Code" --accept-source-agreements > nul 2>&1 || (
    if "%~1"=="/silent" exit /b 1
    set "action=update"
    set "uri=ms-windows-store://downloadsandupdates"
    goto :error
)
exit /b

:error
echo You need the latest version of WinGet to use this script.
echo WinGet is included with 'App Installer' on the Microsoft Store, it's also on GitHub.
echo]
choice /c:yn /n /m "Would you like to open the Microsoft Store to %action% it? [Y/N] "
if %ERRORLEVEL% == 1 start %uri%
exit /b 2