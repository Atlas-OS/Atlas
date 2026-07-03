@echo off
title Enable Click To Do
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ClickToDo -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
