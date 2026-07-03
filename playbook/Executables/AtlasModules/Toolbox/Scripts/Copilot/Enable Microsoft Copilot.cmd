@echo off
title Enable Microsoft Copilot
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Copilot -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
