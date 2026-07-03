@echo off
title Enable Compact View (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name CompactView -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
