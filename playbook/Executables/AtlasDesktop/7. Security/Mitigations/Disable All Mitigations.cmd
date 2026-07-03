@echo off
title Disable All Mitigations
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Mitigations -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
