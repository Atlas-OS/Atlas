@echo off
title Default Power-saving (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name PowerSaving -State Default -LauncherPath "%~f0" %*
exit /b %errorlevel%
