@echo off
set "settingName=Indexing"
set "stateValue=0"
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
    pause
    exit /b 1
)
set "indexConf=call %indexConfPath%"

reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

echo.
echo Disabling search indexing...
%indexConf% /stop

if "%silentMode%"=="1" exit /b

echo.
echo Search Indexing has been disabled.
echo Press any key to exit...
pause > nul
exit /b
