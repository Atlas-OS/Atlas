@echo off
title Enable Delivery Optimization
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name DeliveryOptimisation -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
