@echo off
title Disable Sleep
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Sleep -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
