@echo off
title Enable Recall Support
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Recall -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
