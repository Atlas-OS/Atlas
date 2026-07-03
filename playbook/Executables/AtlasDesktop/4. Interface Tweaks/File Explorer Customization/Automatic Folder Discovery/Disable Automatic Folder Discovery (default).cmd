@echo off
title Disable Automatic Folder Discovery (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name AutomaticFolderDiscovery -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
