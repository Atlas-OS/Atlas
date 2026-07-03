@echo off
title Disable Web Search (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name WebSearch -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
