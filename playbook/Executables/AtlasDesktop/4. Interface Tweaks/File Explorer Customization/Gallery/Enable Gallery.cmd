@echo off
title Enable Gallery
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Gallery -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
