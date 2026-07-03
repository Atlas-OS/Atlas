@echo off
title Disable Automatic Updates (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name AutomaticUpdates -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
