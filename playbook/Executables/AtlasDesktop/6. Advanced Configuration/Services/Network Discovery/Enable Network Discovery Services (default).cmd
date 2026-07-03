@echo off
title Enable Network Discovery Services (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name NetworkDiscovery -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
