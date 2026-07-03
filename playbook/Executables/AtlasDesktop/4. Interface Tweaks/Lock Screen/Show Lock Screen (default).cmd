@echo off
title Show Lock Screen (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name LockScreen -State Show -LauncherPath "%~f0" %*
exit /b %errorlevel%
