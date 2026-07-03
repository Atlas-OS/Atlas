@echo off
title Remove Terminals Context Menu (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ContextMenuTerminals -State Remove -LauncherPath "%~f0" %*
exit /b %errorlevel%
