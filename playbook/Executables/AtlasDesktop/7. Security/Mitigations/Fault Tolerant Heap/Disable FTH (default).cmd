@echo off
title Disable FTH (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name FaultTolerantHeap -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
