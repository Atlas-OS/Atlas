@echo off
title Disable Mobile Device Settings (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name PhoneLink -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
