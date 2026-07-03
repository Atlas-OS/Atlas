@echo off
title Add Extract
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ExtractContextMenu -State Add -LauncherPath "%~f0" %*
exit /b %errorlevel%
