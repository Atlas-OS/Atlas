@echo off

set ___edge=0
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set ___edge=1
if "%~1"=="/webview" set ___edge=1
if %___edge%==1 (
    set "text=WebView2 is"
    set "plural=it"
) else (
    set "text=and Microsoft Edge WebView2 are"
    set "plural=them"
)

set "___dashes=-----------------------------------------------------------------------------------------------------"
echo %___dashes%

echo Microsoft Edge %text% required to use this script.
if %___edge%==0 echo In the future, if you no longer want to use this feature, you can use the disable script and uninstall Edge.
choice /c:yn /n /m "Would you like to install %plural%? [Y/N] "
if %errorlevel%==2 (
    echo]
    echo Press any key to exit...
    pause > nul
    exit /b
)

echo]
set "___ps=powershell -nop -noni -c "^& """%windir%\AtlasModules\Scripts\ScriptWrappers\RemoveEdge.ps1""" -NonInteractive -InstallWebView"
if %___edge%==0 (
	%___ps% -InstallEdge"
) else (
	%___ps%"
)

if "%errorlevel%"=="1" (
    echo Something went wrong while trying to install Edge or WebView.
    if "%~1" neq "/silent" (
        echo Press any key to exit...
        pause > nul
    )
    exit /b 1
)

echo %___dashes%