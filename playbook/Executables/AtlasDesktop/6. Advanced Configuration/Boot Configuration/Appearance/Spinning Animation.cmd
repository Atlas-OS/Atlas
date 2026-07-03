@echo off
title Spinning Animation
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SpinningAnimations -LauncherPath "%~f0" %*
exit /b %errorlevel%
