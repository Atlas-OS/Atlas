@echo off
set "settingName=Indexing"
set "stateValue=1"
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
echo Configuring minimal search indexing...
%indexConf% /stop
%indexConf% /cleanpolicies
%indexConf% /include "%programdata%\Microsoft\Windows\Start Menu\Programs"
%indexConf% /include "%windir%\AtlasDesktop"
%indexConf% /exclude "%systemdrive%\Users"

reg add "HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex" /v "RespectPowerModes" /t REG_DWORD /d 1 /f > nul

%indexConf% /start
reg add "HKLM\SOFTWARE\Microsoft\Windows Search" /v SetupCompletedSuccessfully /t REG_DWORD /d 0 /f > nul

echo.
echo Minimal Search Indexing has been configured.
echo Press any key to exit...
if "%~1" neq "/silent" pause
exit /b
