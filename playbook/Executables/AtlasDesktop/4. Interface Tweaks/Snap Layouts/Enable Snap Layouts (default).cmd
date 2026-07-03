@echo off
title Enable Snap Layouts (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SnapLayouts -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
