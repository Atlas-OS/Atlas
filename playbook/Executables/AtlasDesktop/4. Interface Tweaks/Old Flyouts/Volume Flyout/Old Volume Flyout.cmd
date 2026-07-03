@echo off
title Old Volume Flyout
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ModernVolumeFlyout -State Old -LauncherPath "%~f0" %*
exit /b %errorlevel%
