@echo off

fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	PowerShell Start -Verb RunAs '%0' 2> nul || (
		echo You must run this script as admin.
		exit /b 1
	)
	exit /b
)

if not exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" goto msedgeInstall

:main
taskkill /f /im explorer.exe > nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f > nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "1" /f > nul
start explorer.exe

echo Finished, changes are applied.
echo Press any key to exit...
pause > nul
exit /b

::::::::::::::::::
:: Edge install ::
::::::::::::::::::

:msedgeInstall
echo Microsoft Edge is requried to be installed for Windows Copilot.
choice /c:yn /n /m "Would you like to install it now? [Y/N]"
if %errorlevel%==2 (
    cls
    echo You must have Edge installed to enable Copilot.
    echo Press any key to exit...
    pause > nul
    exit /b 1
)

cls

:: Check if WinGet is functional or not
:: If not, go to download page for Edge instead of using WinGet
echo Checking for WinGet...
call "%windir%\AtlasModules\Scripts\wingetCheck.cmd" /silent
if %ERRORLEVEL% NEQ 0 goto edgeFail

:: Install Edge with WinGet
echo Installing Microsoft Edge with WinGet...
echo]
winget install -e --id Microsoft.Edge -h --accept-source-agreements --accept-package-agreements --force
if %ERRORLEVEL% NEQ 0 (
    echo Edge install with WinGet failed.
    echo]
    goto edgeFail
)

echo]
echo Edge installed successfully! Enabling Copilot...
timeout /t 3 /nobreak > nul
goto main

:edgeFail
start https://www.microsoft.com/en-us/edge/download
echo You must download Edge manually before you enable Copilot.
echo Press any key to exit...
pause > nul
exit /b 2