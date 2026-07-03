@echo off
title Enable All Mitigations
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Mitigations -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
