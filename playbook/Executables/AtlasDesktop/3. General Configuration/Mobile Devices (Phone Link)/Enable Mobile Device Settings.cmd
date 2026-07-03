@echo off
title Enable Mobile Device Settings
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name PhoneLink -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
