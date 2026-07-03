@echo off
title Disable Printing
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Printing -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
