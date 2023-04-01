@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

DevManView.exe /enable "WAN Miniport (IKEv2)"
DevManView.exe /enable "WAN Miniport (IP)"
DevManView.exe /enable "WAN Miniport (IPv6)"
DevManView.exe /enable "WAN Miniport (L2TP)"
DevManView.exe /enable "WAN Miniport (Network Monitor)"
DevManView.exe /enable "WAN Miniport (PPPOE)"
DevManView.exe /enable "WAN Miniport (PPTP)"
DevManView.exe /enable "WAN Miniport (SSTP)"
DevManView.exe /enable "NDIS Virtual Network Adapter Enumerator"
DevManView.exe /enable "Microsoft RRAS Root Enumerator"

!setSvcScript! IKEEXT 3
!setSvcScript! BFE 2
!setSvcScript! WinHttpAutoProxySvc 3
!setSvcScript! RasMan 3
!setSvcScript! SstpSvc 3
!setSvcScript! iphlpsvc 3
!setSvcScript! NdisVirtualBus 3
!setSvcScript! Eaphost 3

echo Finished, please reboot your device for changes to apply.
pause
exit /b