@echo off
title Enable Store App Archiving
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name AppStoreArchiving -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
