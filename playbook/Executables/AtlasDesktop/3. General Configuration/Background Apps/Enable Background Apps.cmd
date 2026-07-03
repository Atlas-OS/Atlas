@echo off
title Enable Background Apps
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name BackgroundApps -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
