@echo off
title Disable Widgets (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Widgets -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
