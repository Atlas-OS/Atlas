@echo off
title Show Quick Access (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name QuickAccess -State Show -LauncherPath "%~f0" %*
exit /b %errorlevel%
