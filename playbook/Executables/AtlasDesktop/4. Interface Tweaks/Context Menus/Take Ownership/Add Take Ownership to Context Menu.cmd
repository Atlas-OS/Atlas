@echo off
title Add Take Ownership to Context Menu
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name TakeOwnership -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
