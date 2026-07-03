@echo off
title Disable Give Access To Menu (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name GiveAccessToMenu -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
