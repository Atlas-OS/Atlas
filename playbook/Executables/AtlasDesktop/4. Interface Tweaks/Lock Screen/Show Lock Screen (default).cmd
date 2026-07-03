@echo off
title Show Lock Screen (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name LockScreen -State Show -LauncherPath "%~f0" %*
exit /b %errorlevel%
