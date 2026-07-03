@echo off
title Disable Idle
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name CpuIdle -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
