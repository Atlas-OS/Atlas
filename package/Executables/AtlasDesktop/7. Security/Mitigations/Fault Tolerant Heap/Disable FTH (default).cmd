@echo off
call "%__APPDIR__%..\AtlasModules\Scripts\Entry\Invoke-AtlasToggleLauncher.cmd" FaultTolerantHeap Disable "%~f0" %*
