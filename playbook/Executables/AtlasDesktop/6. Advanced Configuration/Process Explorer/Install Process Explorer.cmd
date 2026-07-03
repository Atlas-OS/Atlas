@echo off
title Install Process Explorer
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ProcessExplorer -State Install -LauncherPath "%~f0" %*
exit /b %errorlevel%
