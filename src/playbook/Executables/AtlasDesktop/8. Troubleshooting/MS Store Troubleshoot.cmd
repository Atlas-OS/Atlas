@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:: uninstall ms store
powershell -NoP -C "Get-AppxPackage *WindowsStore* | Remove-AppxPackage"

:: reinstall ms store
powershell -NoP -C "winget install 9WZDNCRFJBMP"