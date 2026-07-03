@echo off
title Highest Mode
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name HighestMode -LauncherPath "%~f0" %*
exit /b %errorlevel%
