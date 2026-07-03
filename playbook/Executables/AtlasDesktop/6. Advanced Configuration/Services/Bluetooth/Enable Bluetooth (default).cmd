@echo off
title Enable Bluetooth (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Bluetooth -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
