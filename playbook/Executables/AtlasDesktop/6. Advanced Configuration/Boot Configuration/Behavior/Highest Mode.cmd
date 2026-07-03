@echo off
title Highest Mode
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name HighestMode -LauncherPath "%~f0" %*
exit /b %errorlevel%
