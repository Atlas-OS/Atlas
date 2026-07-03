@echo off
title User Network Navigation Pane choice
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name NetworkNavigationPane -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
