@echo off
setlocal EnableDelayedExpansion
whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	set system=false
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)
set system=true
goto script

----------------------------------------

[CREDITS]
- All credit goes to he3als for this script
- Repo: https://github.com/he3als/setSvc
	
[FEATURES]
- An interactive option, where it will prompt the user about configuring a service
- Automatic elevation to TrustedInstaller (if avaliable) or regular admin (/q argument only)
- Checking whether the service/driver exists or not, and other error detection
- Option to attempt to stop the service/driver being configured
- Ability to use it as a function in scripts (use call (setSvc.cmd path here) "(service)" "(start)" /f)
- Help menu

----------------------------------------

:script
call :setSvc %*
exit /b

:setSvc
:: example: call setSvc.cmd AppInfo 4
:: last argument is the startup type: 0, 1, 2, 3, 4
if [%~1]==[] (echo You need to run this with a service/driver to disable. & exit /b 1)
if [%~2]==[] (echo You need to run this with an argument ^(1-5^) to configure the service's startup. & exit /b 1)
if %~2 LSS 0 (echo Invalid start value ^(%~2^) for %~1. & exit /b 1)
if %~2 GTR 5 (echo Invalid start value ^(%~2^) for %~1. & exit /b 1)
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" > nul 2>&1 || (echo The specified service/driver ^(%~1^) is not found. & exit /b 1)
if "%system%"=="false" (
	if not "%setSvcWarning%"=="false" (
		echo WARNING: Not running as System, could fail modifying some services/drivers with an access denied error.
	)
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v "Start" /t REG_DWORD /d "%~2" /f > nul 2>&1 || (
	if "%system%"=="false" (
		echo Failed to set service %~1 with start value %~2^^! Not running as System, access denied?
		exit /b 1
	) else (
		echo Failed to set service %~1 with start value %~2^^! Unknown error.
		exit /b 1
	)
)
exit /b 0
