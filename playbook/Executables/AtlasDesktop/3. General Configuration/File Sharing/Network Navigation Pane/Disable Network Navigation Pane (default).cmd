@echo off
title Disable Network Navigation Pane (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name NetworkNavigationPane -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
