@echo off
set "script=%windir%\AtlasModules\Scripts\ScriptWrappers\InstallSoftware.ps1"
if not exist "%script%" (
	echo Script not found.
	echo "%script%"
	exit /b 1
)
powershell -EP Bypass -NoP Unblock-File -Path """$env:script""" -EA 0; ^& """$env:script""" %*