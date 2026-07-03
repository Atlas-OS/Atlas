@echo off
title Remove Extract (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ExtractContextMenu -State Remove -LauncherPath "%~f0" %*
exit /b %errorlevel%
