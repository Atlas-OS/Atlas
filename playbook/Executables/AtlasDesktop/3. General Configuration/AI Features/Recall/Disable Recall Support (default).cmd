@echo off
title Disable Recall Support (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Recall -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
