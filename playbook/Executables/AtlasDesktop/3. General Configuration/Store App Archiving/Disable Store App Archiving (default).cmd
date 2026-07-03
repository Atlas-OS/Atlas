@echo off
title Disable Store App Archiving (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name AppStoreArchiving -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
