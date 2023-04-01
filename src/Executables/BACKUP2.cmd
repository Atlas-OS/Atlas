@echo off
setlocal EnableDelayedExpansion

:: Backup default Atlas services
set "filename=C:!HOMEPATH!\Desktop\Atlas\4. Troubleshooting\Services\Default Atlas services.reg"
if exist "!filename!" goto :drivers

echo Backing up services...

echo Windows Registry Editor Version 5.00 >> "!filename!"
echo] >> "!filename!"
for /f "skip=1" %%a in ('wmic service get Name ^| findstr "[a-z]" ^| findstr /v "TermService"') do (
	set svc=%%a
	set svc=!svc: =!
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
		set /a start=%%a
		echo !start!
		echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> "!filename!"
		echo "Start"=dword:0000000!start! >> "!filename!"
		echo] >> "!filename!"
	)
) > nul 2>&1

:drivers
:: Backup default Atlas drivers
set "filename=C:!HOMEPATH!\Desktop\Atlas\4. Troubleshooting\Services\Default Atlas drivers.reg"
if exist "!filename!" exit /b 0

echo Backing up drivers...

echo Windows Registry Editor Version 5.00 >> "!filename!"
echo] >> "!filename!"
for /f "delims=," %%a in ('driverquery /FO CSV') do (
	set svc=%%a
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
		set /a start=%%a
		echo !start!
		echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> "!filename!"
		echo "Start"=dword:0000000!start! >> "!filename!"
		echo] >> "!filename!"
	)
) > nul 2>&1