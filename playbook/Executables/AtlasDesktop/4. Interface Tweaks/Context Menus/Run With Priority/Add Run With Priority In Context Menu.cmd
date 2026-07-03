@echo off
title Add Run With Priority In Context Menu
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name RunWithPriority -State Add -LauncherPath "%~f0" %*
exit /b %errorlevel%
