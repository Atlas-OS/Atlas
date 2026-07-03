@echo off
title Enable Click To Do
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ClickToDo -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
