@echo off
title None (security risk)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ShortcutIcon -State None -LauncherPath "%~f0" %*
exit /b %errorlevel%
