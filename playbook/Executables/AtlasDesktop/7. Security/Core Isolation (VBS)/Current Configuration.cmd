@echo off
title Current Configuration
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ConfigVBS -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
