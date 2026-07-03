@echo off
title Disable Recent Items (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name RecentItems -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
