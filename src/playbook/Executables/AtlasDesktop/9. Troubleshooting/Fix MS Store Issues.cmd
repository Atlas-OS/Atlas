@echo off
cd /d "%~dp0"
echo Current directory: %cd%
echo Looking for: %cd%StoreFixer.exe

if not exist "StoreFixer.exe" (
  echo ERROR: StoreFixer.exe not found!
  echo Please ensure StoreFixer.exe is in the same directory as this script.
  pause
  exit /b 1
)
if "%~1"=="/silent" (
  call RunAsTI.cmd "%windir%\AtlasModules\Tools\StoreFixer.exe" silent -wait
  exit 0
)

call RunAsTI.cmd "%windir%\AtlasModules\Tools\StoreFixer.exe" -wait
