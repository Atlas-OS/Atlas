@echo off
title Disable Verbose Messages (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name VerboseMessages -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
