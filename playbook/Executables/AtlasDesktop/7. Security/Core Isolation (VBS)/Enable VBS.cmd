@echo off
title Enable VBS
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name VbsState -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
