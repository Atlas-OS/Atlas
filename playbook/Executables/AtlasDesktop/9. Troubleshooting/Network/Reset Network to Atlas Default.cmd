@echo off
title Reset Network to Atlas Default
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name DefaultAtlasNetwork -State AtlasDefault -LauncherPath "%~f0" %*
exit /b %errorlevel%
