@echo off
title View Current Values
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ViewCurrentValues -State View -LauncherPath "%~f0" %*
exit /b %errorlevel%
