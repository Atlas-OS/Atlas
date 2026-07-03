@echo off

echo Attempting to remove Python executables from WindowsApps...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -Path \"$env:LOCALAPPDATA\Microsoft\WindowsApps\python*.exe\" -Force -ErrorAction SilentlyContinue; if (Test-Path Alias:python) { Remove-Item Alias:python }; if (Test-Path Alias:python3) { Remove-Item Alias:python3 }"

echo -----------------------------------------
echo Cleanup completed.
if /i not "%~1"=="/silent" pause
exit /b
