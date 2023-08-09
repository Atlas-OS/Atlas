@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	set system=false
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)
set system=true

goto script

----------------------------------------

[CREDITS]
- Made by he3als & Xyueta
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
if [%~1]==[] echo You need to run this with a service/driver to disable.
if [%~2]==[] echo You need to run this with an argument ^(0-4^) to configure the service's startup. 
if %~2 LSS 0 echo Invalid start value ^(%~2^) for %~1.
if %~2 GTR 4 echo Invalid start value ^(%~2^) for %~1.

reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" > nul 2>&1 || (
	echo The specified service/driver ^(%~1^) is not found.
	exit /b 1
)

reg add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v "Start" /t REG_DWORD /d "%~2" /f > nul 2>&1
if not "%errorlevel%"=="0" (
	if "!system!" == "false" (
		echo Failed to set service %~1 with start value %~2^^! Not running as System, access denied?
		exit /b 1
	) else (
		echo Failed to set service %~1 with start value %~2^^! Unknown error.
		exit /b 1
	)
)