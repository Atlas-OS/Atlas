@echo off
title Enable Search Indexing
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Indexing -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
