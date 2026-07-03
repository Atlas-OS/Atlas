@echo off
title Spinning Animation
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name SpinningAnimations -LauncherPath "%~f0" %*
exit /b %errorlevel%
