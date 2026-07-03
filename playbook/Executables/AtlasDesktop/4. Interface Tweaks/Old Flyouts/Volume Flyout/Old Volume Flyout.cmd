@echo off
title Old Volume Flyout
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ModernVolumeFlyout -State Old -LauncherPath "%~f0" %*
exit /b %errorlevel%
