@echo off
title Fix MS Store Issues
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%windir%\AtlasModules\Scripts\Invoke-Toggle.ps1" -Name FixMSStoreIssues -State Run -LauncherPath "%~f0" %*
exit /b %errorlevel%
