@echo off
title Pause Windows Updates
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name PauseUpdates -State Pause -LauncherPath "%~f0" %*
exit /b %errorlevel%
