@echo off
title Install or Remove Edge
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name RemoveEdge -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
