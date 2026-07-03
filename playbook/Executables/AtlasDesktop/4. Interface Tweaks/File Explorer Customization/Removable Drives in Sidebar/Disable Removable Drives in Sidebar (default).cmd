@echo off
title Disable Removable Drives in Sidebar (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name RemovableDrivesInSidebar -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
