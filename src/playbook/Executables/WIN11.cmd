@echo off
setlocal EnableDelayedExpansion

:: Check for a Windows version and exit if W11 is not installed
for /f "tokens=6 delims=[.] " %%a in ('ver') do (
    if %%a lss 22000 (
        exit /b
    )
)

