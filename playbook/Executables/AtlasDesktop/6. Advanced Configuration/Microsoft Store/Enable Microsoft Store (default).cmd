@echo off
title Enable Microsoft Store (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name MicrosoftStore -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
