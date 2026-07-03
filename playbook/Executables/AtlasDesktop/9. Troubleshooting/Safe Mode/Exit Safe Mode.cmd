@echo off
title Exit Safe Mode
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SafeMode -State Exit -LauncherPath "%~f0" %*
exit /b %errorlevel%
