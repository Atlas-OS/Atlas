@echo off
title Disable Sleep Study (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name SleepStudy -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
