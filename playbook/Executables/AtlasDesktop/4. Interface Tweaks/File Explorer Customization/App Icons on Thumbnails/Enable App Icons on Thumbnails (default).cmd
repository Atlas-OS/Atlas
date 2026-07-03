@echo off
title Enable App Icons on Thumbnails (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name AppIconThumbnail -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
