@echo off
title Telemetry Components
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name TelemetryComponents -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
