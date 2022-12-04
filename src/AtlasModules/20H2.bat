@echo off
DevManView.exe /disable "WAN Miniport (IKEv2)"
DevManView.exe /disable "WAN Miniport (IP)"
DevManView.exe /disable "WAN Miniport (IPv6)"
DevManView.exe /disable "WAN Miniport (L2TP)"
DevManView.exe /disable "WAN Miniport (Network Monitor)"
DevManView.exe /disable "WAN Miniport (PPPOE)"
DevManView.exe /disable "WAN Miniport (PPTP)"
DevManView.exe /disable "WAN Miniport (SSTP)"

:: enable Hardware Accelerated Scheduling
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d "2" /f

:: disable Memory Compression
powershell -NoProfile -Command "Disable-MMAgent -mc"
goto :EOF