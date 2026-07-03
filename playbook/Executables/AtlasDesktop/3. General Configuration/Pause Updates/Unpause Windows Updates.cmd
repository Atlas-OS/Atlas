@echo off
title Unpause Windows Updates
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name PauseUpdates -State Unpause -LauncherPath "%~f0" %*
exit /b %errorlevel%
