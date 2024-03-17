@echo off

set "___dashes=-----------------------------------------------------------------------------------------------------"
echo %___dashes%

echo Microsoft Edge and Microsoft Edge WebView2 are required to use this script.
choice /c:yn /n /m "Would you like to install them? [Y/N] "
if %errorlevel%==2 exit

echo]
set "___ps=powershell -nop -noni -c "^& """%windir%\AtlasModules\Scripts\ScriptWrappers\RemoveEdge.ps1""" -NonInteractive -InstallWebView"
if not exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
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
    exit 1
)

echo %___dashes%