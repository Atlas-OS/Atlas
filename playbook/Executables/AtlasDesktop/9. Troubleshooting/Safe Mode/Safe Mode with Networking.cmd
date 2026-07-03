@echo off
title Safe Mode with Networking
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SafeMode -State Networking -LauncherPath "%~f0" %*
exit /b %errorlevel%
