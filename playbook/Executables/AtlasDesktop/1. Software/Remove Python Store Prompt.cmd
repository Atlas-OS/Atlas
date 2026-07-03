@echo off
title Remove Python Store Prompt
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name RemovePythonStorePrompt -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
