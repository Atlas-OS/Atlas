@echo off

if "%~1"=="/silent" goto main

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

:main
:: Enable Lanman Workstation (SMB) as a dependency
call "%windir%\AtlasDesktop\3. Configuration\Lanman Workstation (SMB)\Enable Lanman Workstation (default).cmd" /silent
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

if "%~1"=="/silent" exit /b

echo Finished, please reboot your device for changes to apply.
pause
exit /b