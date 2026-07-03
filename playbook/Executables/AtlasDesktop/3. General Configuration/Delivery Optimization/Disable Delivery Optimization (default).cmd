@echo off
title Disable Delivery Optimization (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name DeliveryOptimisation -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
