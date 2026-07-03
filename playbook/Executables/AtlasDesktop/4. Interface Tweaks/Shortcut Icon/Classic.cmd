@echo off
title Classic
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ShortcutIcon -State Classic -LauncherPath "%~f0" %*
exit /b %errorlevel%
