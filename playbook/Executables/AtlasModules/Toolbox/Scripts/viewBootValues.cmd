@echo off
title viewBootValues
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ViewCurrentValues -State View -LauncherPath "%~f0" %*
exit /b %errorlevel%
