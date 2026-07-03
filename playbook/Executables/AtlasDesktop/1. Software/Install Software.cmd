@echo off
set "script=%windir%\AtlasModules\Scripts\ScriptWrappers\InstallSoftware.ps1"
if not exist "%script%" (
	echo Script not found.
	echo "%script%"
	if /i not "%~1"=="/silent" pause
	exit /b 1
)
powershell -EP Bypass -NoP ^& """$env:script""" %*