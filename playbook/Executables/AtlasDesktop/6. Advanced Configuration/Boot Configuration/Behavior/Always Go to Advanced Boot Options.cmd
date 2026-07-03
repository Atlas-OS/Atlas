@echo off
title Always Go to Advanced Boot Options
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name AdvancedBootOptions -LauncherPath "%~f0" %*
exit /b %errorlevel%
