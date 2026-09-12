@echo off
REM Verifies the EBOS configuration (services, policies, power plan, theme, OEM).
REM Usage: run normally for a report, or with -FixIssues to repair (needs admin).

set "script=%~dp0Verify-EBOS.ps1"
if not exist "%script%" (
	echo Verify-EBOS.ps1 not found next to this script, can't continue.
	if "%*"=="" pause
	exit /b 1
)

fltmc > nul 2>&1 || (
	echo Administrator privileges are recommended (HKLM checks are skipped without them).
	echo]
)

if "%~1"=="" (
	powershell -NoProfile -ExecutionPolicy Bypass -File "%script%" -DetailedOutput
) else (
	powershell -NoProfile -ExecutionPolicy Bypass -File "%script%" %*
)
if "%*"=="" pause
exit /b %errorlevel%
