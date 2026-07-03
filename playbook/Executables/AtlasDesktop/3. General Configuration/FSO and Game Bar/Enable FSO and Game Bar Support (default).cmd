@echo off
title Enable FSO and Game Bar Support (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name FSOGameBar -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
