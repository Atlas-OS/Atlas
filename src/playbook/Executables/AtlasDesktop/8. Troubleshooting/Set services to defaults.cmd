@echo off
set "title=call :title"
set "servicesPath=%windir%\AtlasDesktop\6. Advanced Configuration\Services"
if not exist "%servicesPath%" (
	echo Services in Atlas folder not found, can't continue.
	if "%*"=="" pause
	exit /b 1
)
if "%~1"=="/silent" goto main

:: TI required for full services restore
whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

echo This will reset the configuration of services in the Atlas folder.
echo Disabling services often breaks features, and if you're experiencing an issue, this might help.
echo]
choice /c:yn /n /m "Continue? [Y/N] "
if %errorlevel% neq 1 exit /b

:main
%title% "Enabling services in the Atlas folder... This might take a while."
for /f "usebackq tokens=*" %%a in (`dir /b /s "%windir%\AtlasDesktop\6. Advanced Configuration\Services" ^| find "(default)"`) do (
	call :run "%%a"
	start /min /high /wait cmd /c "%%a" /silent
)

set "atlasOther=%windir%\AtlasModules\Other"
set "winServices=%atlasOther%\winServices.reg"
set "atlasServices=%atlasOther%\atlasServices.reg"
if exist "%winServices%" (
	if exist "%atlasServices%" call :fullRestore
)

%title% "Finished."
if "%~1"=="/silent" exit /b
echo A restart is required to apply the changes.
choice /c:yn /n /m "Would you like to restart now? [Y/N] "
if "%errorlevel%"=="1" shutdown /r /t 0
exit /b

:fullRestore
%title% "Full services restoration"
echo What would you like to do?
echo]
echo 1) Restore a full services backup of the default Windows services
echo 2) Restore a full services backup of the default Atlas services
echo 3) Nothing
echo]
choice /c:123 /n /m "Choose a number: [1/2/3] "
if "%errorlevel%"=="1" reg import "%winServices%" > nul
if "%errorlevel%"=="2" reg import "%atlasServices%" > nul
exit /b


:::::::::::::::
:: Functions ::
    exit /b
:::::::::::::::

:: https://ss64.com/nt/syntax-strlen.html
:strlen  StrVar  [RtnVar]
	setlocal EnableDelayedExpansion
	set "s=#!%~1!"
	set "len=0"
	for %%N in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
    	if "!s:~%%N,1!" neq "" (
      		set /a "len+=%%N"
      		set "s=!s:~%%N!"
    	)
  	)
	endlocal&if "%~2" neq "" (set %~2=%len%) else echo %len%
	exit /b

:title
	set "titleString=%~1"
	call :strlen titleString dashLen
	echo] & echo]
	for /l %%a in (1,1,%dashLen%) do <nul set /p="-"
	echo]
	echo %titleString%
	for /l %%a in (1,1,%dashLen%) do <nul set /p="-"
	echo]
	exit /b

:run
	echo Running "%~nx1"...
	exit /b
