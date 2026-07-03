@echo off
title Disable System Restore
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name SystemRestore -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
