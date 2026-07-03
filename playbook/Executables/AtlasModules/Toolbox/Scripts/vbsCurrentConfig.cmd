@echo off
title vbsCurrentConfig
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ConfigVBS -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
