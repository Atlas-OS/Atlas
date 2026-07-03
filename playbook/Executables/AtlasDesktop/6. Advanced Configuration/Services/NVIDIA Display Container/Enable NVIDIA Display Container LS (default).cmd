@echo off
title Enable NVIDIA Display Container LS (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name NVidiaDisplayContainer -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
