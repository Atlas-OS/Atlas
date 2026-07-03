@echo off
title DisableMicrosoftCopilot
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name Copilot -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
