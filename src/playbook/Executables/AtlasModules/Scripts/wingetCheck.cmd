@echo off

set "dashes=-----------------------------------------------------------------------------------------------------"
set "silent="
echo "%~1 %~2" | find "/silent" > nul && set silent=true

if not defined silent echo %dashes%

ping -n 1 -4 www.microsoft.com > nul 2>&1
if errorlevel == 1 (
    if defined silent exit /b 2
	echo You must have an internet connection to continue.
	if not defined silent (
        echo Press any key to exit...
	    pause > nul
    )
	exit /b 2
)

:main
if not defined silent echo Checking for WinGet...

where winget > nul 2>&1 || (
    if defined silent exit /b 1
    if defined edge goto edgeFail
    set "action=install"
    set "uri=ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
    goto error
)
winget search "Microsoft Visual Studio Code" --accept-source-agreements > nul 2>&1 || (
    if defined silent exit /b 1
    if defined edge goto edgeFail
    set "action=update"
    set "uri=ms-windows-store://downloadsandupdates"
    goto error
)

if not defined silent (
    echo %dashes%
    echo]
)

exit /b

:error
cls
echo You need the latest version of WinGet to use this script.
echo WinGet is included with 'App Installer' on the Microsoft Store, it's also on GitHub.
echo]
choice /c:yn /n /m "Would you like to open the Microsoft Store to %action% it? [Y/N] "
if errorlevel == 1 start %uri%
exit /b 2