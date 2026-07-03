@echo off
title Toggle Windows Updates
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ToggleWindowsUpdates -LauncherPath "%~f0" %*
exit /b %errorlevel%
