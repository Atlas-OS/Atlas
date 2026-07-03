@echo off
title Disable Lanman Workstation
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name LanmanWorkstation -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
