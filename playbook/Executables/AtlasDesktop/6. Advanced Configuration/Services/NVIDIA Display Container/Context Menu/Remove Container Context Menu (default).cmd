@echo off
title Remove Container Context Menu (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name NVidiaDisplayContainerContextMenu -State Remove -LauncherPath "%~f0" %*
exit /b %errorlevel%
