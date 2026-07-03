@echo off
title Add Container Context Menu
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name NVidiaDisplayContainerContextMenu -State Add -LauncherPath "%~f0" %*
exit /b %errorlevel%
