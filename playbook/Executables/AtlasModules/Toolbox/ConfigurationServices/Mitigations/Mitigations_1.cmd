@echo off
title Mitigations_1
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Mitigations -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
