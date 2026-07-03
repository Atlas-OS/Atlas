@echo off
title Disallow Edge Swipe
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name EdgeSwipe -State Disallow -LauncherPath "%~f0" %*
exit /b %errorlevel%
