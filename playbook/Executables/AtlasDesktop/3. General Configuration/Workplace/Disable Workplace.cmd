@echo off
title Disable Workplace
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Workplace -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
