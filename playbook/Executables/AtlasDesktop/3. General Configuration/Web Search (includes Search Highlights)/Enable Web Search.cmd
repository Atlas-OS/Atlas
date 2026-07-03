@echo off
title Enable Web Search
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name WebSearch -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
