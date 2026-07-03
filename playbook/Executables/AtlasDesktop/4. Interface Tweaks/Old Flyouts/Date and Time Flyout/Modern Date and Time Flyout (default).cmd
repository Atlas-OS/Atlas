@echo off
title Modern Date and Time Flyout (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ModernDateTime -State Modern -LauncherPath "%~f0" %*
exit /b %errorlevel%
