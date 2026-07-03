@echo off
title Enable Mobile Device Settings
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name PhoneLink -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
