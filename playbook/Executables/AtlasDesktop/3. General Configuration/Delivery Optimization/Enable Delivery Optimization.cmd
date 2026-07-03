@echo off
title Enable Delivery Optimization
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name DeliveryOptimisation -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
