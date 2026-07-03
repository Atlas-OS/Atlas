@echo off
title Modern Volume Flyout (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ModernVolumeFlyout -State Modern -LauncherPath "%~f0" %*
exit /b %errorlevel%
