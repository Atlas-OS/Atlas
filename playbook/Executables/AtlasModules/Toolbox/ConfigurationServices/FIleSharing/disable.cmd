@echo off
title disable
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name FileSharing -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
