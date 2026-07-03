@echo off
title Enable File Sharing
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name FileSharing -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
