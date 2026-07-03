@echo off
title Enable Sleep Study
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SleepStudy -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
