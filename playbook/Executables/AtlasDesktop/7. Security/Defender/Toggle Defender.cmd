@echo off
title Toggle Defender
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ToggleDefender -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
