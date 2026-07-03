@echo off
set "script=%windir%\AtlasModules\Scripts\ScriptWrappers\ToggleDefender.ps1"
if not exist "%script%" (
	echo Script not found.
	echo "%script%"
	pause
	exit /b 1
)

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

powershell -EP Bypass -NoP ^& """$env:script""" %*