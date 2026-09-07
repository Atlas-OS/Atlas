@echo off
setlocal EnableExtensions DisableDelayedExpansion

if not "%~1"=="" (
    >&2 echo Initialize-NewUser does not accept command-line arguments.
    exit /b 2
)

set "script=%~dp0Initialize-NewUser.ps1"
set "powershell=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%script%" exit /b 1
if not exist "%powershell%" exit /b 1

"%powershell%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%script%"
exit /b %errorlevel%
