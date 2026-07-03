@echo off
title Add Idle Toggle in Desktop Context Menu
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name CpuIdleContextMenu -State Add -LauncherPath "%~f0" %*
exit /b %errorlevel%
