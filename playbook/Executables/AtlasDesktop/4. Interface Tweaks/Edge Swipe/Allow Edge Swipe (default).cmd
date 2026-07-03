@echo off
title Allow Edge Swipe (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name EdgeSwipe -State Allow -LauncherPath "%~f0" %*
exit /b %errorlevel%
