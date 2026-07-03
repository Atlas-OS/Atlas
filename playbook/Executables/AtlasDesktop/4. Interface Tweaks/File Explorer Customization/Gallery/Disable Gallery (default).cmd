@echo off
title Disable Gallery (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Gallery -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
