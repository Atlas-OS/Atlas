@echo off
title Disable timer resolution (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name TimerResolution -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
