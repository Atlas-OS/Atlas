@echo off
title Enable Lanman Workstation (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name LanmanWorkstation -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
