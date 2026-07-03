@echo off
title Enable FTH
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name FaultTolerantHeap -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
