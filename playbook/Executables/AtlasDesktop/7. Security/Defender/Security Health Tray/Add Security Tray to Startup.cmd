@echo off
title Add Security Tray to Startup
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name SecurityHealthTray -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
