@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

DevManView.exe /disable "WAN Miniport (IKEv2)"
DevManView.exe /disable "WAN Miniport (IP)"
DevManView.exe /disable "WAN Miniport (IPv6)"
DevManView.exe /disable "WAN Miniport (L2TP)"
DevManView.exe /disable "WAN Miniport (Network Monitor)"
DevManView.exe /disable "WAN Miniport (PPPOE)"
DevManView.exe /disable "WAN Miniport (PPTP)"
DevManView.exe /disable "WAN Miniport (SSTP)"
DevManView.exe /disable "NDIS Virtual Network Adapter Enumerator"
DevManView.exe /disable "Microsoft RRAS Root Enumerator"

!setSvcScript! IKEEXT 4
!setSvcScript! WinHttpAutoProxySvc 4
!setSvcScript! RasMan 4
!setSvcScript! SstpSvc 4
!setSvcScript! iphlpsvc 4
!setSvcScript! NdisVirtualBus 4
!setSvcScript! Eaphost 4

echo Finished, please reboot your device for changes to apply.
pause
exit /b