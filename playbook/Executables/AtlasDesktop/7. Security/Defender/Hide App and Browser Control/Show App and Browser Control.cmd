@echo off
title Show App and Browser Control
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name HideAppBrowserControl -State Show -LauncherPath "%~f0" %*
exit /b %errorlevel%
