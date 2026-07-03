@echo off
title Fix Errors 2502 and 2503
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name FixErrors2502and2503 -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
