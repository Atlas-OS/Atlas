@echo off

set "dashes=-----------------------------------------------------------------------------------------------------"
set "silent=" & set "edge=" & set "edgeNotExist="
echo "%~1 %~2" | find "/silent" > nul && set silent=true
echo "%~1 %~2" | find "/edge" > nul && set edge=true

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

if defined edge (
    if not exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
        set edgeNotExist=true

        if not defined silent (
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

    goto webviewInstall
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

if defined edgeNotExist (
    echo Installing Microsoft Edge with WinGet...
    echo]

    winget install -e --id Microsoft.Edge -h --accept-source-agreements --accept-package-agreements --force || goto edgeFail
)

if not defined silent (
    echo %dashes%
    echo]
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

:webviewInstall
if not defined silent (
    echo Installing Microsoft Edge WebView 2...
    echo This might take a while.
    echo]
)

set "webviewExe=webview%random%%random%%random%%random%.exe"
set "webviewPath=%temp%\%webviewExe%"
curl -Ls "https://go.microsoft.com/fwlink/p/?LinkId=2124703" -o "%webviewPath%"
start /b "" cmd /c "%webviewPath%" /silent /install
set webviewCheck=1

:checkIfWebviewRuns
timeout /t 2 /nobreak > nul

if "%webviewCheck%"=="80" (
    if not defined silent (
        echo It seems like Edge WebView is taking a while to install.
        echo You can skip waiting for its installation and move on anyways.
        echo However, continuing without Edge WebView could break the functionality of this script.
        echo]
        choice /c:yn /n /m "Would you like to continue anyways? [Y/N] "
        if errorlevel == 2 (
            set webviewCheck=1
        ) else (
            goto main
        )
    ) else (
        goto main
    )
)

tasklist | find "%webviewExe%" > nul
if %errorlevel%==0 (
    set /a webviewCheck=%webviewCheck% + 1
    goto checkIfWebviewRuns
)

goto main