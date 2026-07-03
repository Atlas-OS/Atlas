@echo off
title DisableSuperFetch
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name SuperFetch -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
