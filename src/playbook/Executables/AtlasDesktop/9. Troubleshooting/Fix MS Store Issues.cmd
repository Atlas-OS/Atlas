@echo off
setlocal EnableDelayedExpansion

echo Running as Trusted Installer

if not exist "%windir%\AtlasModules\Tools\StoreFixer.exe" (
  echo ERROR: StoreFixer.exe not found!
  echo Please ensure StoreFixer.exe is in the same directory as this script.
  pause
  exit /b 1
)
if "%~1"=="/silent" (
  echo Running StoreFixer.exe silently...
  call RunAsTi.cmd "%windir%\AtlasModules\Tools\StoreFixer.exe" silent -wait
  exit 0
)

echo Running StoreFixer.exe...
RunAsTi.cmd "%windir%\AtlasModules\Tools\StoreFixer.exe" -wait
echo StoreFixer.exe completed.
pause
