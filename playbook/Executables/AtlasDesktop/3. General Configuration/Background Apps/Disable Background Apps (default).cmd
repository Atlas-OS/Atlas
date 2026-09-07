@echo off
call "%__APPDIR__%..\AtlasModules\Scripts\Entry\Invoke-AtlasToggleLauncher.cmd" BackgroundApps Disable "%~f0" %*
