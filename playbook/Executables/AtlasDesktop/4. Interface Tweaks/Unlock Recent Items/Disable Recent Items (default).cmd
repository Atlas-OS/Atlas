@echo off
title Disable Recent Items (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name RecentItems -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
