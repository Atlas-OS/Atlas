@echo off
title Disable Search Indexing
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Indexing -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
