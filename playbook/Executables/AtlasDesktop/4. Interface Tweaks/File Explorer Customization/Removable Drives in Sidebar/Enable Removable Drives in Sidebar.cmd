@echo off
title Enable Removable Drives in Sidebar
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name RemovableDrivesInSidebar -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
