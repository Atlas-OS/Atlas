@echo off
title disable
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name FileSharing -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
