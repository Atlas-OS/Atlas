@echo off
title Uninstall Process Explorer
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ProcessExplorer -State Uninstall -LauncherPath "%~f0" %*
exit /b %errorlevel%
