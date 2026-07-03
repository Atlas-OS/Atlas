@echo off
title Default Power-saving (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name PowerSaving -State Default -LauncherPath "%~f0" %*
exit /b %errorlevel%
