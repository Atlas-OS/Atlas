@echo off
title SafeMode_2
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SafeMode -State Networking -LauncherPath "%~f0" %*
exit /b %errorlevel%
