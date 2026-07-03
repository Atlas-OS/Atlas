@echo off
title Enable timer resolution
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name TimerResolution -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
