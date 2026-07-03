@echo off
title Minimal Search Indexing (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Indexing -State Minimal -LauncherPath "%~f0" %*
exit /b %errorlevel%
