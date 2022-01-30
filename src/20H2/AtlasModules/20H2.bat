@echo off
devmanview /disable "WAN Miniport (IKEv2)"
devmanview /disable "WAN Miniport (IP)"
devmanview /disable "WAN Miniport (IPv6)"
devmanview /disable "WAN Miniport (L2TP)"
devmanview /disable "WAN Miniport (Network Monitor)"
devmanview /disable "WAN Miniport (PPPOE)"
devmanview /disable "WAN Miniport (PPTP)"
devmanview /disable "WAN Miniport (SSTP)"

:: Disable Network Adapters
:: IPv6
powershell -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6"
:: Client for Microsoft Networks
powershell -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_msclient"
:: QoS Packet Scheduler
powershell -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_pacer"
:: File and Printer Sharing
powershell -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_server"

:: Enable Hardware Accelerated Scheduling
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d "2" /f

:: Disable Memory Compression
powershell -NoProfile -Command "Disable-MMAgent -mc"
goto :EOF