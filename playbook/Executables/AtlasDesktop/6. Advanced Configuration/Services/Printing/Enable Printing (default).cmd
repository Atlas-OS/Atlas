@echo off
title Enable Printing (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Printing -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
