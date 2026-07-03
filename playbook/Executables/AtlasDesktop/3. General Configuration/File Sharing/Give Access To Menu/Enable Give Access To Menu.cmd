@echo off
title Enable Give Access To Menu
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name GiveAccessToMenu -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
