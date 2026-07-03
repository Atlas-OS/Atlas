@echo off
title Hide Lock Screen
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name LockScreen -State Hide -LauncherPath "%~f0" %*
exit /b %errorlevel%
