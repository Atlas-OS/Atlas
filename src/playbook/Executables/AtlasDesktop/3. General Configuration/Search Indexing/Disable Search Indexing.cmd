@echo off
set "settingName=Indexing"
set "stateValue=0"
set "scriptPath=%~f0"
set indexConfPath="%windir%\AtlasModules\Scripts\indexConf.cmd"
set "silentMode=0"
for %%a in (%*) do (
    if /I "%%a"=="/silent" set "silentMode=1"
    if /I "%%a"=="-silent" set "silentMode=1"
    if /I "%%a"=="/quiet" set "silentMode=1"
)

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
    call "%windir%\AtlasModules\Scripts\RunAsTI.cmd" "%~f0" %*
    exit /b
)

if not exist "%indexConfPath%" (
    if "%silentMode%"=="0" (
        echo The 'indexConf.cmd' script wasn't found in AtlasModules.
        pause
    )
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
