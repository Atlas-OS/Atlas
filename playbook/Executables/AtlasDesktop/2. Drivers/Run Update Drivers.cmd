@echo off
title Run Update Drivers
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name UpdateDrivers -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
