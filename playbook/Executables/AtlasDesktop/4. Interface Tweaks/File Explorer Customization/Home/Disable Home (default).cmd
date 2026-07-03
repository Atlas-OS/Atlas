@echo off
title Disable Home (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Home -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
