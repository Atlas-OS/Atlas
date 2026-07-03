@echo off
title SafeMode_0
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name SafeMode -State Exit -LauncherPath "%~f0" %*
exit /b %errorlevel%
