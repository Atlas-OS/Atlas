@echo off
title Disable Click To Do (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ClickToDo -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
