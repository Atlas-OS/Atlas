@echo off
title Disable App Icons on Thumbnails
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name AppIconThumbnail -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
