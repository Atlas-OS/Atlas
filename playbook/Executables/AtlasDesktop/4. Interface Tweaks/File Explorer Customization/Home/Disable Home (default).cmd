@echo off
title Disable Home (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Home -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
