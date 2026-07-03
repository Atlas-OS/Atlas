@echo off
title Disable Sleep
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Sleep -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
