@echo off
title Enable Automatic Updates
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name AutomaticUpdates -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
