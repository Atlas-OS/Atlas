@echo off
title Safe Mode with Command Prompt
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name SafeMode -State CommandPrompt -LauncherPath "%~f0" %*
exit /b %errorlevel%
