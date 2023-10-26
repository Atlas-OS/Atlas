@echo off
:: Simple script to check if WinGet is functional or not

where winget > nul 2>&1 || (
    if "%~1"=="/silent" exit 1
    set "action=install"
    set "uri=ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
    goto :error
)
start /wait /min winget search "Microsoft Visual Studio Code" --accept-source-agreements > nul 2>&1 || (
    if "%~1"=="/silent" exit 1
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
if "%errorlevel%" == "1" start %uri%
exit /b 1