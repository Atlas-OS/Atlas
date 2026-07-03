@echo off
title Enable Location
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Location -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
