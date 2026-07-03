@echo off
title Remove Quick Access
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name QuickAccess -State Remove -LauncherPath "%~f0" %*
exit /b %errorlevel%
