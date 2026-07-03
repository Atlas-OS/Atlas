@echo off
title Old Context Menu (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name OldContextMenu -State Old -LauncherPath "%~f0" %*
exit /b %errorlevel%
