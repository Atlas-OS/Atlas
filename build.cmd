@echo off
setlocal
pushd "%~dp0" || exit /b 1
set "buildExit=1"
echo Building Playbook...
where pwsh >nul 2>&1
if errorlevel 1 (
    echo PowerShell 7 ^(pwsh^) is required. See docs\building.md.
    set "buildExit=9009"
    goto :finish
)

pwsh -NoProfile -ExecutionPolicy Bypass -File "%cd%\tools\build\Build-Playbook.ps1" -LocalTest
set "buildExit=%errorlevel%"
if not "%buildExit%"=="0" if "%~1"=="" pause

:finish
popd
exit /b %buildExit%
