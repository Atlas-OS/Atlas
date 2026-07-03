@echo off
title Enable Idle (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name CpuIdle -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
