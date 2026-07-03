@echo off
title Disable Microsoft Copilot (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name Copilot -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
