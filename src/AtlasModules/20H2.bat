@echo off

:: disable network devices
DevManView /disable "WAN Miniport (IKEv2)"
DevManView /disable "WAN Miniport (IP)"
DevManView /disable "WAN Miniport (IPv6)"
DevManView /disable "WAN Miniport (L2TP)"
DevManView /disable "WAN Miniport (Network Monitor)"
DevManView /disable "WAN Miniport (PPPOE)"
DevManView /disable "WAN Miniport (PPTP)"
DevManView /disable "WAN Miniport (SSTP)"

:: disable reserved storage
DISM /Online /Set-ReservedStorageState /State:Disabled
goto :EOF
