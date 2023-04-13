@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

PowerShell -NoP -C "Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ 'Xbox' | Remove-AppxProvisionedPackage -Online"

echo Finished, changes have been applied.
pause
exit /b