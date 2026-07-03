@echo off
title Enable timer resolution
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name TimerResolution -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
