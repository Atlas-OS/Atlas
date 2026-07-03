@echo off
title Toggle Defender
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ToggleDefender -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
