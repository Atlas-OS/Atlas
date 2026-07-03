@echo off
title Remove Idle Toggle in Desktop Context Menu (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name CpuIdleContextMenu -State Remove -LauncherPath "%~f0" %*
exit /b %errorlevel%
