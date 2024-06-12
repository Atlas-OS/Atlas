@echo off

if "%~1"=="/silent" goto main

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
		echo You must run this script as admin.
		if "%*"=="" pause
		exit /b 1
	)
	exit /b
)

:main
setlocal EnableDelayedExpansion

:: Add lower filters for rdyboost driver
set "key=HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}"
for /f "skip=1 tokens=3*" %%a in ('reg query "!key!" /v "LowerFilters"') do (set val=%%a)

echo "!val!" > nul | findstr /c:"rdyboost"
if !errorlevel! NEQ 0 (
	set "val=!val!\0rdyboost"
	reg add "!key!" /v "LowerFilters" /t REG_MULTI_SZ /d "!val!" /f
)

:: Enable ReadyBoost
reg add "HKLM\SYSTEM\CurrentControlSet\Services\rdyboost" /v "Start" /t REG_DWORD /d "0" /f > nul

:: Add ReadyBoost tab
reg add "HKCR\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}" /f > nul

:: Enable SysMain (Prefetch, Memory Management features)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v "Start" /t REG_DWORD /d "2" /f > nul

if "%~1"=="/silent" exit /b

echo Finished, please reboot your device for changes to apply.
pause
exit /b