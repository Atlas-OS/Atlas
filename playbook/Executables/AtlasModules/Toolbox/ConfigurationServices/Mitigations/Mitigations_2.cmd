@echo off
title Mitigations_2
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Mitigations -State WindowsDefault -LauncherPath "%~f0" %*
exit /b %errorlevel%
