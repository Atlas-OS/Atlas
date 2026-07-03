@echo off
title Disable Click To Do (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ClickToDo -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
