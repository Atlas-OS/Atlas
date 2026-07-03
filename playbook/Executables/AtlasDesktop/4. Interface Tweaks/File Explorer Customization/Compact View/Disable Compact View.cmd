@echo off
title Disable Compact View
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name CompactView -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
