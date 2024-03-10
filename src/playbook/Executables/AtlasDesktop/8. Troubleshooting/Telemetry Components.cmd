@echo off
set "script=%windir%\AtlasModules\Scripts\ScriptWrappers\TelemetryComponents.ps1"
if not exist "%script%" (
	echo Script not found.
	echo "%script%"
	pause
	exit /b 1
)

fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	set "___args="%~f0" %*"
	powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
		echo You must run this script as admin.
		exit /b 1
	)
	exit /b
)

powershell -EP Bypass -NoP ^& """$env:script""" %*