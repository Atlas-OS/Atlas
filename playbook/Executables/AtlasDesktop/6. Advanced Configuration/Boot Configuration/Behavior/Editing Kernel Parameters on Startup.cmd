@echo off
title Editing Kernel Parameters on Startup
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name KernelParameters -LauncherPath "%~f0" %*
exit /b %errorlevel%
