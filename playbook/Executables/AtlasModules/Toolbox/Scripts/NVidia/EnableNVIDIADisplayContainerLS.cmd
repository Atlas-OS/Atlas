@echo off
title EnableNVIDIADisplayContainerLS
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name NVidiaDisplayContainer -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
