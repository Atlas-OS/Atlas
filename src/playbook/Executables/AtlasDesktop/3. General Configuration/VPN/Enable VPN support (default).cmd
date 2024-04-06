@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

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

echo Finished, please reboot your device for changes to apply.
pause
exit /b