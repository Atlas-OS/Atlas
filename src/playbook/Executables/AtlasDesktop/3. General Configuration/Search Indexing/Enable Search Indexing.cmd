@echo off
setlocal EnableDelayedExpansion
set indexConfPath="%windir%\AtlasModules\Scripts\indexConf.cmd"
if not exist %indexConfPath% (
	echo The 'indexConf.cmd' script wasn't found in AtlasModules.
	if "%~1"=="" pause
	exit /b 1
)
set "indexConf=call %indexConfPath%"

if "%~1" neq "" goto main
:: TI required for RespectPowerModes
whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:main
echo ===================================
echo Enabling search indexing...
echo ===================================
echo]

%indexConf% /stop

%indexConf% /cleanpolicies
%indexConf% /include "%programdata%\Microsoft\Windows\Start Menu\Programs"
:: The Atlas folder is so that if the user searches for a Atlas-modified feature, a script shows up in search
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

echo]
:: Respect Power Settings when Search Indexing to prevent performance loss during gaming or battery drain
choice /c:yn /n /m "Would you like to have indexing disable its self when on battery or gaming? [Y/N] "
if %errorlevel%==1 %regCmd% "1" /f
if %errorlevel%==2 %regCmd% "0" /f

echo Finished, there might be some CPU usage for a period while indexing.
pause
exit /b