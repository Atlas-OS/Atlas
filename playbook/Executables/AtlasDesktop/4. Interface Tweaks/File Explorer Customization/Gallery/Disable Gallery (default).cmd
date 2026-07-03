@echo off
title Disable Gallery (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Gallery -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
