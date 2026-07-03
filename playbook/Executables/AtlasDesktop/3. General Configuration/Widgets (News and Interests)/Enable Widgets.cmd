@echo off
title Enable Widgets
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Widgets -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
