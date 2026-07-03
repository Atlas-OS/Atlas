@echo off
title Disable NVIDIA Display Container LS
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name NVidiaDisplayContainer -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
