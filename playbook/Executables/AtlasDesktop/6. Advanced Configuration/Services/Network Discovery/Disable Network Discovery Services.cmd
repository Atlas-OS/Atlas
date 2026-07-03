@echo off
title Disable Network Discovery Services
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name NetworkDiscovery -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
