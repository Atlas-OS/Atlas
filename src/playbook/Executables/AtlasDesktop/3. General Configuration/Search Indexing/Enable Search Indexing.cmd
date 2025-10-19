@echo off
set "settingName=Indexing"
set "stateValue=2"
set "scriptPath=%~f0"
set indexConfPath="%windir%\AtlasModules\Scripts\indexConf.cmd"

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
    call RunAsTI.cmd "%~f0" %*
    exit /b
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
echo Enabling full search indexing...
%indexConf% /stop
%indexConf% /cleanpolicies
%indexConf% /include "%programdata%\Microsoft\Windows\Start Menu\Programs"
%indexConf% /include "%windir%\AtlasDesktop"
%indexConf% /include "%systemdrive%\Users"

:: Add default user exclusions
for /f "usebackq delims=" %%a in (`dir /b /a:d "%SystemDrive%\Users"`) do (
	for %%z in (
		"AppData"
		"MicrosoftEdgeBackups"
	) do (
		if exist "%SystemDrive%\Users\%%~a\%%~z" %indexConf% /exclude "%SystemDrive%\Users\%%~a\%%~z"
	)
)

%indexConf% /start
reg add "HKLM\SOFTWARE\Microsoft\Windows Search" /v SetupCompletedSuccessfully /t REG_DWORD /d 0 /f > nul

set regCmd=^>nul reg add "HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex" /v "RespectPowerModes" /t REG_DWORD /d 
if "%~1"=="/silent" (%regCmd% "0" /f & exit /b)

echo.
:: Respect Power Settings when Search Indexing to prevent performance loss during gaming or battery drain
choice /c:yn /n /m "Would you like to have indexing disable itself when on battery or gaming? [Y/N] "
if %errorlevel%==1 %regCmd% "1" /f
if %errorlevel%==2 %regCmd% "0" /f

echo.
echo Full Search Indexing has been enabled.
echo Press any key to exit...
pause > nul
exit /b
