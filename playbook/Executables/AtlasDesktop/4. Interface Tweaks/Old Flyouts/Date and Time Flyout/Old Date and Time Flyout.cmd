@echo off
title Old Date and Time Flyout
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ModernDateTime -State Old -LauncherPath "%~f0" %*
exit /b %errorlevel%
