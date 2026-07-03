@echo off
title EnableSuperFetch
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SuperFetch -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
