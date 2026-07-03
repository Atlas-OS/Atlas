@echo off
title Remove Take Ownership to Context Menu (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name TakeOwnership -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
