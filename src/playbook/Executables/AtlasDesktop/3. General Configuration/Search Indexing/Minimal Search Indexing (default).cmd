@echo off
set "settingName=Indexing"
set "stateValue=1"
set "scriptPath=%~f0"
set indexConfPath="%windir%\AtlasModules\Scripts\indexConf.cmd"
set "silentMode=0"

echo %* | findstr /i /c:"/silent" /c:"-silent" /c:"/quiet" > nul 2>&1 && set "silentMode=1"

if "%silentMode%"=="1" (
    fltmc > nul 2>&1 || (
        call RunAsTI.cmd "%~f0" %*
        exit /b
    )
) else (
    whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
        call RunAsTI.cmd "%~f0" %*
        exit /b
    )
)

if not exist "%indexConfPath%" (
    echo The 'indexConf.cmd' script wasn't found in AtlasModules.
    if "%silentMode%"=="1" exit /b 1
    pause
    exit /b 1
)
set "indexConf=call %indexConfPath%"

reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

if "%silentMode%"=="0" (
    echo.
    echo Configuring minimal search indexing...
)
%indexConf% /stop
%indexConf% /cleanpolicies
%indexConf% /include "%programdata%\Microsoft\Windows\Start Menu\Programs"
%indexConf% /include "%windir%\AtlasDesktop"
%indexConf% /exclude "%systemdrive%\Users"

reg add "HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex" /v "RespectPowerModes" /t REG_DWORD /d 1 /f > nul

%indexConf% /start
reg add "HKLM\SOFTWARE\Microsoft\Windows Search" /v SetupCompletedSuccessfully /t REG_DWORD /d 0 /f > nul

if "%silentMode%"=="1" exit /b

echo.
echo Minimal Search Indexing has been configured.
echo Press any key to exit...
pause
exit /b
