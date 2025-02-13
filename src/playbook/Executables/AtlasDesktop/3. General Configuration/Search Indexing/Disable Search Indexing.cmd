@echo off
set "settingName=Indexing"
set "stateValue=0"
set "scriptPath=%~f0"
set indexConfPath="%windir%\AtlasModules\Scripts\indexConf.cmd"

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

if not exist "%indexConfPath%" (
    echo The 'indexConf.cmd' script wasn't found in AtlasModules.
    pause
    exit /b 1
)
set "indexConf=call %indexConfPath%"

reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

echo.
echo Disabling search indexing...
%indexConf% /stop

echo.
echo Search Indexing has been disabled.
echo Press any key to exit...
pause > nul
exit /b
