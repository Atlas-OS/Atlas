@echo off
title Toggle Windows Updates
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ToggleWindowsUpdates -LauncherPath "%~f0" %*
exit /b %errorlevel%
