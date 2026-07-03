@echo off
title Repair Windows Components
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name RepairWindowsComponents -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
