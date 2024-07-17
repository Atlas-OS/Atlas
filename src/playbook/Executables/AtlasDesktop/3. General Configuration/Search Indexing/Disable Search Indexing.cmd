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

:main
echo ===================================
echo Disabling search indexing...
echo ===================================
echo]

%indexConf% /stop

echo]
echo Finished.
if "%~1" neq "/silent" pause
exit /b