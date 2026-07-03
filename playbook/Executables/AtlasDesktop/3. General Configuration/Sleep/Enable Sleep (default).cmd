@echo off
title Enable Sleep (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Sleep -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
