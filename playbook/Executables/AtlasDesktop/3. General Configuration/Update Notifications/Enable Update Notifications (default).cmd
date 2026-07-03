@echo off
title Enable Update Notifications (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name UpdateNotifications -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
