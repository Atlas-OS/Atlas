@echo off
title Modern Battery Flyout (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ModernBatteryFlyout -State Modern -LauncherPath "%~f0" %*
exit /b %errorlevel%
