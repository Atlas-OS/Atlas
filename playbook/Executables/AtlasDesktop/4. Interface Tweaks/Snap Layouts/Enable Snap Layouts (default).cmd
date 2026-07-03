@echo off
title Enable Snap Layouts (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name SnapLayouts -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
