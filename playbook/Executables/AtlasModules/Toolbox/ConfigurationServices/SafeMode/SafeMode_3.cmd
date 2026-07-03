@echo off
title SafeMode_3
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name SafeMode -State Minimal -LauncherPath "%~f0" %*
exit /b %errorlevel%
