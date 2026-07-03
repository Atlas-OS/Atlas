@echo off
title Disable Background Apps (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name BackgroundApps -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
