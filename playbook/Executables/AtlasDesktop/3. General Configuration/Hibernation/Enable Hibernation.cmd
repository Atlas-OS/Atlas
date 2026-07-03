@echo off
title Enable Hibernation
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Hibernation -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
