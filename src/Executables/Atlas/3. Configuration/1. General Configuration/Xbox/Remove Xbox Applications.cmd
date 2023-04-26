@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Remove Xbox applications using wildcards
PowerShell -NoP -C "Get-ProvisionedAppxPackage -Online | Where-Object { $_.PackageName -match 'Xbox' } | ForEach-Object { Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName }"

:: Restart explorer.exe for the immediate effect
taskkill /f /im explorer.exe & explorer.exe

cls & echo Finished, changes have been applied.
pause
exit /b