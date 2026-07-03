@echo off
title Automatic Repair
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name AutomaticRepair -LauncherPath "%~f0" %*
exit /b %errorlevel%
