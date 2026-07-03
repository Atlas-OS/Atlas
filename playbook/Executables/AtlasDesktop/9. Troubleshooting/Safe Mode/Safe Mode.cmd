@echo off
title Safe Mode
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SafeMode -State Minimal -LauncherPath "%~f0" %*
exit /b %errorlevel%
