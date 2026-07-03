@echo off
title Enable File Sharing
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name FileSharing -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
