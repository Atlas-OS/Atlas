@echo off

echo Attempting to remove Python executables from WindowsApps...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Remove-Item -Path \"$env:LOCALAPPDATA\Microsoft\WindowsApps\python*.exe\" -Force -ErrorAction SilentlyContinue; ^

echo Checking and removing 'python' alias if it exists...
 if (Test-Path Alias:python) { Remove-Item Alias:python }; ^

echo Checking and removing 'python3' alias if it exists...
 if (Test-Path Alias:python3) { Remove-Item Alias:python3 };

echo -----------------------------------------
echo Cleanup completed.
pause
exit /b