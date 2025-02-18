@echo off
set "script=%windir%\AtlasModules\Scripts\ScriptWrappers\UpdateDrivers.ps1"

if not exist "%script%" (
    echo Script not found: "%script%"
    pause
    exit /b 1
)

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
    call RunAsTI.cmd "%~f0" %*
    exit /b
)

@REM The "echo Y" is to bypass the NuGet installation user prompt.
@REM If there's a better way, feel free to PR.
echo Y | powershell -ExecutionPolicy Bypass -NoProfile -File "%script%"

pause
exit /b 0
