@echo off
title Atlas Visual Effects (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Animation -State Atlas -LauncherPath "%~f0" %*
exit /b %errorlevel%
