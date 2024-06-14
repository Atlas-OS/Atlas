@echo off
setlocal EnableDelayedExpansion

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
call toggleDev.cmd -Silent -Enable @("NDIS Virtual Network Adapter Enumerator", "Microsoft RRAS Root Enumerator", "WAN Miniport*")

for %%a in (
	"SstpSvc"
	"WinHttpAutoProxySvc"
	"iphlpsvc"
	"NdisVirtualBus"
	"IKEEXT"
	"Eaphost"
) do (
	call setSvc.cmd %%~a 3
)
call setSvc.cmd BFE 2
call setSvc.cmd RasMan 2

call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide network-vpn /silent

if "%~1"=="/silent" exit /b

echo Finished, please reboot your device for changes to apply.
pause
exit /b