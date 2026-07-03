@echo off
title Enable System Restore (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SystemRestore -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
