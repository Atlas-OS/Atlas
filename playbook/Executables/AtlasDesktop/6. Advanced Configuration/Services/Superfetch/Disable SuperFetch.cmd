@echo off
title Disable SuperFetch
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SuperFetch -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
