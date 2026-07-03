@echo off
title Enable Update Notifications (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name UpdateNotifications -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
