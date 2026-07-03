@echo off
title Reset Network to Windows Default
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name DefaultAtlasNetwork -State WindowsDefault -LauncherPath "%~f0" %*
exit /b %errorlevel%
