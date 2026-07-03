@echo off
title Enable Windows Spotlight
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name WindowsSpotlight -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
