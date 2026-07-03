@echo off
title Enable Automatic Folder Discovery
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name AutomaticFolderDiscovery -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
