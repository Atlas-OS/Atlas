@echo off
title Enable Hibernation
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Hibernation -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
