@echo off
set "settingName=Copilot"
set "stateValue=1"
set "scriptPath=%~f0"

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
    echo Administrator privileges are required.
    powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
        echo You must run this script as admin.
        if "%*"=="" pause
        exit /b 1
    )
    exit /b
)

reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul


:: Check for Edge support
echo]
call "%windir%\AtlasModules\Scripts\edgeCheck.cmd" /edgeonly
if %errorlevel% neq 0 exit /b 1
echo]

echo Enabling Copilot...

:: Decide if Copilot is avaliable
:: If not, it could be 24H2 (which replaces it with an app)
set "appText= "
reg query HKCU\Software\Microsoft\Windows\Shell\Copilot /v IsCopilotAvailable 2>&1 | find "0x0" > nul
if %errorlevel%==0 (call :app) else (reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "1" /f > nul)

taskkill /f /im explorer.exe > nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f > nul 2>&1
start explorer.exe

:finish
echo]
echo Finished, changes are applied. %appText%
echo Press any key to exit...
pause > nul
exit /b

:app
echo NOTE: Copilot on the taskbar isn't available, the app will be installed instead.
set "appText=You can find the Copilot app in your Start Menu."
call "%windir%\AtlasModules\Scripts\wingetCheck.cmd" /nodashes
if %errorlevel% neq 0 exit /b 1
echo Installing Copilot...
winget install -e --id 9NHT9RB2F4HD --uninstall-previous -h --accept-source-agreements --accept-package-agreements --force --disable-interactivity > nul