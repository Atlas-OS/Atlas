@echo off
title Enable Bluetooth (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Bluetooth -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
