@echo off
title Telemetry Components
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name TelemetryComponents -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
