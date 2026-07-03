@echo off
title Disable Widgets (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Widgets -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
