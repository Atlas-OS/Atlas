@echo off
title Hide Lock Screen
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name LockScreen -State Hide -LauncherPath "%~f0" %*
exit /b %errorlevel%
