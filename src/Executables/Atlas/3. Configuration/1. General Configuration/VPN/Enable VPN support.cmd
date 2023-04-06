@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

call toggleDev.cmd /e "WAN Miniport*" "NDIS Virtual Network Adapter Enumerator" "Microsoft RRAS Root Enumerator"

call setSvc,cmd IKEEXT 3
call setSvc,cmd BFE 2
call setSvc,cmd WinHttpAutoProxySvc 3
call setSvc,cmd RasMan 3
call setSvc,cmd SstpSvc 3
call setSvc,cmd iphlpsvc 3
call setSvc,cmd NdisVirtualBus 3
call setSvc,cmd Eaphost 3

echo Finished, please reboot your device for changes to apply.
pause
exit /b