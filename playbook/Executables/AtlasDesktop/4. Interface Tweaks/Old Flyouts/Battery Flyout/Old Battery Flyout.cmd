@echo off
title Old Battery Flyout
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ModernBatteryFlyout -State Old -LauncherPath "%~f0" %*
exit /b %errorlevel%
