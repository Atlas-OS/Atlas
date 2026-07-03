@echo off
title Default Windows Visual Effects
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Animation -State Default -LauncherPath "%~f0" %*
exit /b %errorlevel%
