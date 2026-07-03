@echo off
title Default Windows (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ShortcutIcon -State Default -LauncherPath "%~f0" %*
exit /b %errorlevel%
