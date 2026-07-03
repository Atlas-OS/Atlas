@echo off
title Disable Update Notifications
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name UpdateNotifications -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
