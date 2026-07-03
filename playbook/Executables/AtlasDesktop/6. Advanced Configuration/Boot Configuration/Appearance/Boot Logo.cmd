@echo off
title Boot Logo
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name BootLogo -LauncherPath "%~f0" %*
exit /b %errorlevel%
