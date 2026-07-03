@echo off
title Disable Hibernation (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Hibernation -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
