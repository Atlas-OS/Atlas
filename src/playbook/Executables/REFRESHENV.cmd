@echo off
:: a batch script to refresh environment variables from the registry
:: source: https://raw.githubusercontent.com/chocolatey-archive/chocolatey/master/src/redirects/RefreshEnv.cmd
:: modified by Xyueta

:main
echo/@echo off >"%TEMP%\_env.cmd"
call :GetRegEnv "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" >> "%TEMP%\_env.cmd"
call :GetRegEnv "HKCU\Environment">>"%TEMP%\_env.cmd" >> "%TEMP%\_env.cmd"
call :SetFromReg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" Path Path_HKLM >> "%TEMP%\_env.cmd"
call :SetFromReg "HKCU\Environment" Path Path_HKCU >> "%TEMP%\_env.cmd"
echo/set "Path=%%Path_HKLM%%;%%Path_HKCU%%" >> "%TEMP%\_env.cmd"
del /f /q "%TEMP%\_envset.tmp" > nul 2>&1
del /f /q "%TEMP%\_envget.tmp" > nul 2>&1
set "OriginalUserName=%USERNAME%"
set "OriginalArchitecture=%PROCESSOR_ARCHITECTURE%"
call "%TEMP%\_env.cmd"
del /f /q "%TEMP%\_env.cmd" > nul 2>&1
set "USERNAME=%OriginalUserName%"
set "PROCESSOR_ARCHITECTURE=%OriginalArchitecture%"
exit /b

:SetFromReg
reg query "%~1" /v "%~2" > "%TEMP%\_envset.tmp" 2>NUL
for /f "usebackq skip=2 tokens=2,*" %%a in ("%TEMP%\_envset.tmp") do (
    echo/set "%~3=%%b"
)
goto :eof

:GetRegEnv
reg query "%~1" > "%TEMP%\_envget.tmp"
for /f "usebackq skip=2" %%a in ("%TEMP%\_envget.tmp") do (
    if /I not "%%~a" == "Path" (
        call :SetFromReg "%~1" "%%~a" "%%~a"
    )
)
goto :eof