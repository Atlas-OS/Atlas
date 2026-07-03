@echo off
title Hide App and Browser Control (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name HideAppBrowserControl -State Hide -LauncherPath "%~f0" %*
exit /b %errorlevel%
