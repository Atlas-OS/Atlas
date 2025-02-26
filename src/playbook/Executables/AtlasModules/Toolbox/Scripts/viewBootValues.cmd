@echo off

for /f "skip=3 delims=" %%a in ('bcdedit /enum {current}') do (echo %%a)
echo]
echo Press any key to exit...
pause > nul
exit /b