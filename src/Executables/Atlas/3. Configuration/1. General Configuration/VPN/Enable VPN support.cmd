@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

call ToggleDevices.cmd /e "WAN Miniport*" "NDIS Virtual Network Adapter Enumerator" "Microsoft RRAS Root Enumerator"

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