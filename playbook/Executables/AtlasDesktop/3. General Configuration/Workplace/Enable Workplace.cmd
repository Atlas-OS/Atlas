@echo off
title Enable Workplace
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Workplace -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
