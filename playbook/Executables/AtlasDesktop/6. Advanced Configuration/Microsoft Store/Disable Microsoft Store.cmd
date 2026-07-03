@echo off
title Disable Microsoft Store
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name MicrosoftStore -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
