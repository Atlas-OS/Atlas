@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

call ToggleDevices.cmd "WAN Miniport*" "NDIS Virtual Network Adapter Enumerator" "Microsoft RRAS Root Enumerator"

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