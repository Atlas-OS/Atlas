@echo off
title Disable Shortcut Text (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ShortcutText -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
