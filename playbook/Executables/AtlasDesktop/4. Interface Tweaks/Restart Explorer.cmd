@echo off
title Restart Explorer
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name RestartExplorer -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
