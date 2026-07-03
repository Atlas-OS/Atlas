@echo off
title Enable NVIDIA Display Container LS (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name NVidiaDisplayContainer -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
