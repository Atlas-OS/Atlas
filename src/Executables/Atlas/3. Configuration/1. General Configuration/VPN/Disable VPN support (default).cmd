@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

call toggleDev.cmd "NDIS Virtual Network Adapter Enumerator" "Microsoft RRAS Root Enumerator" "WAN Miniport*"

call setSvc.cmd Eaphost 4
call setSvc.cmd IKEEXT 4
call setSvc.cmd iphlpsvc 4
call setSvc.cmd NdisVirtualBus 4
call setSvc.cmd RasMan 4
call setSvc.cmd SstpSvc 4
call setSvc.cmd WinHttpAutoProxySvc 4

cls & echo Finished, please reboot your device for changes to apply.
pause
exit /b