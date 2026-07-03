@echo off
title Disable Search Indexing
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Indexing -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
