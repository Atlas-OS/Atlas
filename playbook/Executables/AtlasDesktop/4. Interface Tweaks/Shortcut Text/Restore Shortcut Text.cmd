@echo off
title Restore Shortcut Text
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name ShortcutText -State Restore -LauncherPath "%~f0" %*
exit /b %errorlevel%
