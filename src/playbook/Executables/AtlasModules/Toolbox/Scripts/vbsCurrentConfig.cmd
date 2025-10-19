@echo off
set "script=%windir%\AtlasModules\Scripts\ScriptWrappers\ConfigVBS.ps1"
if not exist "%script%" (
	echo Script not found.
	echo "%script%"
	pause
	exit /b 1
)
powershell -EP Bypass -NoP ^& """$env:script""" %*