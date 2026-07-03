@echo off
title Disable Snap Layouts
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name SnapLayouts -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
