@echo off
title Remove Run With Priority In Context Menu (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name RunWithPriority -State Remove -LauncherPath "%~f0" %*
exit /b %errorlevel%
