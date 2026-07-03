@echo off
title Disable Power-saving
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name PowerSaving -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
