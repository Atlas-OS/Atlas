@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
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

call "%windir%\AtlasModules\Scripts\settingsPages.cmd" /unhide network-vpn /silent

echo Finished, please reboot your device for changes to apply.
pause
exit /b