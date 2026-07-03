@echo off
title Mitigations_0
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Mitigations -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
