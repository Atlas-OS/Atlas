@echo off
call "%__APPDIR__%..\AtlasModules\Scripts\Entry\Invoke-AtlasToggleLauncher.cmd" TakeOwnership Disable "%~f0" %*
