@echo off

if "%~1" == "/silent" goto main

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
:: Enable Lanman Workstation (SMB) as a dependency
call "%windir%\AtlasDesktop\6. Advanced Configuration\Services\Lanman Workstation (SMB)\Enable Lanman Workstation (default).cmd" /silent
:: Enable EventLog as a dependency
call setSvc.cmd eventlog 2

call setSvc.cmd fdPHost 3
call setSvc.cmd FDResPub 3
call setSvc.cmd lmhosts 3
call setSvc.cmd netman 3
for /f "tokens=6 delims=[.] " %%a in ('ver') do (
    if %%a LSS 22000 (call setSvc.cmd NlaSvc 2) else (call setSvc.cmd NlaSvc 3)
)
call setSvc.cmd SSDPSRV 3

if "%~1" == "/silent" exit /b

echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b