@echo off
title Enable Verbose Messages
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name VerboseMessages -State Enable -LauncherPath "%~f0" %*
exit /b %errorlevel%
