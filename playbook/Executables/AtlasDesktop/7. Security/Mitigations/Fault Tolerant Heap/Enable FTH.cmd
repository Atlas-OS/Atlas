@echo off
title Enable FTH
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name FaultTolerantHeap -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
