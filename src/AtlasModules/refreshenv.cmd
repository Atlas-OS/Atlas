@echo off
:: a batch script to refresh environment variables from the registry
:: source: https://raw.githubusercontent.com/chocolatey-archive/chocolatey/master/src/redirects/RefreshEnv.cmd
:: modified by Xyueta

echo | set /p dummy="Refreshing environment variables. Please wait..."
goto main

:SetFromReg
reg query "%~1" /v "%~2" > "%temp%\_envset.tmp" 2>NUL
for /f "usebackq skip=2 tokens=2,*" %%a in ("%temp%\_envset.tmp") do (
    echo/set "%~3=%%b"
)
goto :eof

:GetRegEnv
reg query "%~1" > "%temp%\_envget.tmp"
for /f "usebackq skip=2" %%a in ("%temp%\_envget.tmp") do (
    if /I not "%%~a"=="Path" (
        call :SetFromReg "%~1" "%%~a" "%%~a"
    )
)
goto :eof

:main
echo/@echo off >"%temp%\_env.cmd"
call :GetRegEnv "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" >> "%temp%\_env.cmd"
call :GetRegEnv "HKCU\Environment">>"%temp%\_env.cmd" >> "%temp%\_env.cmd"
call :SetFromReg "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" Path Path_HKLM >> "%temp%\_env.cmd"
call :SetFromReg "HKCU\Environment" Path Path_HKCU >> "%temp%\_env.cmd"
echo/set "Path=%%Path_HKLM%%;%%Path_HKCU%%" >> "%temp%\_env.cmd"
del /f /q "%temp%\_envset.tmp" 2>nul
del /f /q "%temp%\_envget.tmp" 2>nul
set "OriginalUserName=%USERNAME%"
set "OriginalArchitecture=%PROCESSOR_ARCHITECTURE%"
call "%temp%\_env.cmd"
del /f /q "%temp%\_env.cmd" 2>nul
set "USERNAME=%OriginalUserName%"
set "PROCESSOR_ARCHITECTURE=%OriginalArchitecture%"
goto :eof