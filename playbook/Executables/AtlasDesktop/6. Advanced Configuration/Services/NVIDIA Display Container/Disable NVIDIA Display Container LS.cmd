@echo off
title Disable NVIDIA Display Container LS
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name NVidiaDisplayContainer -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
