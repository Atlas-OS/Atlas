@echo off
set "script=%windir%\AtlasModules\Scripts\Internal\DebloatSendToContextMenu.ps1"

if not exist "%script%" (
	echo Script not found.
	echo "%script%"
	if /i not "%~1"=="/silent" pause
	exit /b 1
)

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args""" -WindowStyle Minimized" 2> nul || (
		echo You must run this script as admin.
		if "%*"=="" pause
		exit /b 1
	)
	exit /b
)

powershell -EP Bypass -NoP ^& """$env:script""" %*