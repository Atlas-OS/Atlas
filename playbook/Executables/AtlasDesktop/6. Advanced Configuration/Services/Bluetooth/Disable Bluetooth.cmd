@echo off
title Disable Bluetooth
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Bluetooth -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
