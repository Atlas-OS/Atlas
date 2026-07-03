@echo off
title Modern Volume Flyout (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ModernVolumeFlyout -State Modern -LauncherPath "%~f0" %*
exit /b %errorlevel%
