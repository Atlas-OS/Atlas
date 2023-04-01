@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

PowerShell -NoP -C "Get-AppxPackage *Xbox* | Remove-AppxPackage"

echo Finished, changes have been applied.
pause
exit /b