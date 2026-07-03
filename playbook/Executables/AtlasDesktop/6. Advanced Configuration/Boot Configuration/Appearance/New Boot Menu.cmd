@echo off
title New Boot Menu
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name NewBootMenu -LauncherPath "%~f0" %*
exit /b %errorlevel%
