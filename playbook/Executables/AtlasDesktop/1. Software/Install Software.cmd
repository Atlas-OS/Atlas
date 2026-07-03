@echo off
title Install Software
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name InstallSoftware -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
