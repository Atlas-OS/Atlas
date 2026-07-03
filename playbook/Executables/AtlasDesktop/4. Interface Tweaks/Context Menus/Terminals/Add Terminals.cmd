@echo off
title Add Terminals
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ContextMenuTerminals -State Add -LauncherPath "%~f0" %*
exit /b %errorlevel%
