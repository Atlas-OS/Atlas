@echo off
title Disable Store App Archiving (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name AppStoreArchiving -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
