@echo off
set "script=%windir%\AtlasModules\Scripts\newUsers.ps1"
set "logDir=%ProgramData%\AtlasOS\Logs"
set "log=%logDir%\newUsers.log"

if not exist "%logDir%" mkdir "%logDir%" > nul 2>&1
>> "%log%" echo [%date% %time%] newUsers.cmd started.

if not exist "%script%" (
    >> "%log%" echo [%date% %time%] Script not found: "%script%"
    echo Script not found: "%script%"
    pause
    exit /b 1
)

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
    >> "%log%" echo [%date% %time%] Not running as SYSTEM. Relaunching through RunAsTI.
    call "%~dp0RunAsTI.cmd" "%~f0" %*
    set "rc=%ERRORLEVEL%"
    >> "%log%" echo [%date% %time%] RunAsTI returned %rc%.
    exit /b %rc%
)

>> "%log%" echo [%date% %time%] Running "%script%".
powershell -ExecutionPolicy RemoteSigned -NoProfile -File "%script%" >> "%log%" 2>&1
set "rc=%ERRORLEVEL%"
>> "%log%" echo [%date% %time%] PowerShell returned %rc%.

if not "%rc%"=="0" (
    echo Atlas new user setup failed. See "%log%".
)

pause
exit /b %rc%
