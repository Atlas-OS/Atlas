@echo off

set "silent=" & set "edge=" & set "edgeNotExist="
echo "%~1 %~2" | find "/silent" > nul && set silent=true
echo "%~1 %~2" | find "/edge" > nul && set edge=true

if defined edge (
    if not exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
        set edgeNotExist=true

        echo Microsoft Edge is requried to be installed for the action this script is performing.
        choice /c:yn /n /m "Would you like to install it? [Y/N]"
        if errorlevel == 2 (
            echo]
            echo You must have Edge installed.
            echo Press any key to exit...
            pause > nul
            exit /b 1
        )
        echo]
    )
)

if not defined silent echo Checking for WinGet...

ping -n 1 -4 www.microsoft.com > nul 2>&1
if errorlevel == 1 (
    if defined silent exit /b 2
	echo You must have an internet connection to continue.
	echo Press any key to exit...
	pause > nul
	exit /b 2
)

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

if defined edgeNotExist (
    echo Installing Microsoft Edge with WinGet...
    echo]

    winget install -e --id Microsoft.Edge -h --accept-source-agreements --accept-package-agreements --force || goto edgeFail

    echo]
    echo Edge installed successfully! Continuing...
)

exit /b

:error
echo You need the latest version of WinGet to use this script.
echo WinGet is included with 'App Installer' on the Microsoft Store, it's also on GitHub.
echo]
choice /c:yn /n /m "Would you like to open the Microsoft Store to %action% it? [Y/N] "
if errorlevel == 1 start %uri%
exit /b 2

:edgeFail
echo Edge install with WinGet failed.
echo]
echo You must download Edge manually before you enable Copilot.
echo Press any key to exit and open the download page...
pause > nul
start https://www.microsoft.com/edge/download
exit /b 2