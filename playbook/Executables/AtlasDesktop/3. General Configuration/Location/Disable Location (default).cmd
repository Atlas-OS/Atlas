@echo off
title Disable Location (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Location -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
