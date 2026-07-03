@echo off
title Disable FSO and Game Bar Support
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name FSOGameBar -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
