@echo off
title New Context Menu
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name OldContextMenu -State New -LauncherPath "%~f0" %*
exit /b %errorlevel%
