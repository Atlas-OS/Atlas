@echo off
title Disable VBS
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name VbsState -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
