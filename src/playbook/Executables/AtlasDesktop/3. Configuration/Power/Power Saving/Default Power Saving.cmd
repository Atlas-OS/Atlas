@echo off
set "script=%windir%\AtlasModules\Scripts\ScriptWrappers\DefaultPowerSaving.ps1"

if not exist "%script%" (
	echo Script not found.
	echo "%script%"
	pause
	exit /b 1
)

fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList '/c "%0" %*' 2> nul || (
		echo You must run this script as admin.
		exit /b 1
	)
	exit /b
)

powershell -EP Bypass -NoP Unblock-File -Path """$env:script""" -EA 0; ^& """$env:script""" %*