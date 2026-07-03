@echo off
title New Boot Menu
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name NewBootMenu -LauncherPath "%~f0" %*
exit /b %errorlevel%
