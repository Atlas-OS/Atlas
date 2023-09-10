@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

for /f "skip=3 delims=" %%a in ('bcdedit /enum {current}') do (echo %%a)
echo]
echo Press any key to exit...
pause > nul
exit /b