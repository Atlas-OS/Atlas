@echo off
title Unlock Recent Items
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name RecentItems -State Unlock -LauncherPath "%~f0" %*
exit /b %errorlevel%
