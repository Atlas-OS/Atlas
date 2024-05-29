@echo off
setlocal EnableDelayedExpansion

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

call toggleDev.cmd -Silent @("NDIS Virtual Network Adapter Enumerator", "Microsoft RRAS Root Enumerator", "WAN Miniport*")

for %%a in (
	"Eaphost"
	"IKEEXT"
	"iphlpsvc"
	"NdisVirtualBus"
	"RasMan"
	"SstpSvc"
	"WinHttpAutoProxySvc"
) do (
	call setSvc.cmd %%~a 4
)

call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /hide network-vpn /silent

echo Finished, please reboot your device for changes to apply.
pause
exit /b