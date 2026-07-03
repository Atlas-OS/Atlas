@echo off
title Add Terminals (no Windows Terminal)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name ContextMenuTerminals -State AddNoWindowsTerminal -LauncherPath "%~f0" %*
exit /b %errorlevel%
