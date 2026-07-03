@echo off
title Remove Security Tray from Startup (default)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\invokeToggle.ps1" -Name SecurityHealthTray -State Disable -LauncherPath "%~f0" %*
exit /b %errorlevel%
